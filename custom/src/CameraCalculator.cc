#include "CameraCalculator.h"

#include <array>
#include <cmath>

#include <QtCore/QVariantList>
#include <QtCore/QVariantMap>
#include <QtMath>

namespace
{
    constexpr double IMAGE_WIDTH  = 3088.0;
    constexpr double IMAGE_HEIGHT = 2076.0;

    constexpr double HORIZONTAL_FOV_DEG = 25.4;
    constexpr double VERTICAL_FOV_DEG   = 17.7;

    // Native-image pixels. A click on the scaled video maps to more than one sensor pixel.
    constexpr double CLICK_SIGMA_PIXELS = 2.0;
    constexpr double ALTITUDE_STD_BIAS_M = 0.15;
    constexpr double ALTITUDE_STD_FRACTION = 0.05;
    constexpr double MIN_POS_STD_M = 0.05;
    constexpr double MIN_YAW_STD_RAD = 5.0 * M_PI / 180.0;

    QVariantList quaternionToVariantList(const std::array<double, 4> &q)
    {
        return {q[0], q[1], q[2], q[3]};
    }
}

CameraCalculator::CameraCalculator(QObject *parent)
    : QObject(parent)
{
}

void CameraCalculator::imageToBodyFrdMeters(
    double targetX,
    double targetY,
    double altitudeMeters,
    double &forwardMeters,
    double &rightMeters
) const
{
    if (altitudeMeters <= 0.0) {
        forwardMeters = 0.0;
        rightMeters = 0.0;
        return;
    }

    const double cx = IMAGE_WIDTH  / 2.0;
    const double cy = IMAGE_HEIGHT / 2.0;
    const double nx = (targetX - cx) / cx;
    const double ny = (targetY - cy) / cy;
    const double halfHFov = qDegreesToRadians(HORIZONTAL_FOV_DEG / 2.0);
    const double halfVFov = qDegreesToRadians(VERTICAL_FOV_DEG / 2.0);

    rightMeters = altitudeMeters * nx * qTan(halfHFov);
    forwardMeters = -altitudeMeters * ny * qTan(halfVFov);
}

double CameraCalculator::calculateGroundDistance(
    double targetX,
    double targetY,
    double altitudeMeters
) const
{
    double forwardMeters = 0.0;
    double rightMeters = 0.0;
    imageToBodyFrdMeters(targetX, targetY, altitudeMeters, forwardMeters, rightMeters);
    return qSqrt(forwardMeters * forwardMeters + rightMeters * rightMeters);
}

double CameraCalculator::calculateDistanceToTarget(
    double targetX,
    double targetY,
    double altitudeMeters
) const
{
    if (altitudeMeters <= 0.0) {
        return 0.0;
    }

    const double groundDistance = calculateGroundDistance(targetX, targetY, altitudeMeters);
    return qSqrt(altitudeMeters * altitudeMeters + groundDistance * groundDistance);
}

double CameraCalculator::calculateTimeInSeconds(double altitudeMeters) const
{
    if (altitudeMeters <= 0.0) {
        return 0.0;
    }
    return qSqrt((2 * altitudeMeters) / 9.81);
}

QGeoCoordinate CameraCalculator::calculateTargetCoordinate(
    double targetX,
    double targetY,
    double altitudeMeters,
    const QGeoCoordinate &droneCoordinate,
    double headingDegrees
) const
{
    if (!droneCoordinate.isValid()) {
        return QGeoCoordinate();
    }

    double forwardOffset = 0.0;
    double rightOffset = 0.0;
    imageToBodyFrdMeters(targetX, targetY, altitudeMeters, forwardOffset, rightOffset);

    const double groundDistance = calculateGroundDistance(targetX, targetY, altitudeMeters);
    const double relativeBearingDeg = qRadiansToDegrees(qAtan2(rightOffset, forwardOffset));
    const double absoluteBearingDeg = std::fmod(headingDegrees + relativeBearingDeg + 360.0, 360.0);

    return droneCoordinate.atDistanceAndAzimuth(groundDistance, absoluteBearingDeg);
}

std::array<double, 4> CameraCalculator::bodyToNedQuaternion(
    double rollDegrees,
    double pitchDegrees,
    double yawDegrees
) const
{
    const double roll = qDegreesToRadians(rollDegrees);
    const double pitch = qDegreesToRadians(pitchDegrees);
    const double yaw = qDegreesToRadians(yawDegrees);

    const double cr = qCos(roll * 0.5);
    const double sr = qSin(roll * 0.5);
    const double cp = qCos(pitch * 0.5);
    const double sp = qSin(pitch * 0.5);
    const double cy = qCos(yaw * 0.5);
    const double sy = qSin(yaw * 0.5);

    // ZYX aircraft quaternion, body FRD → NED, Hamilton (w, x, y, z).
    std::array<double, 4> q = {
        cr * cp * cy + sr * sp * sy,
        sr * cp * cy - cr * sp * sy,
        cr * sp * cy + sr * cp * sy,
        cr * cp * sy - sr * sp * cy,
    };

    const double norm = qSqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);
    if (norm <= 0.0) {
        return {1.0, 0.0, 0.0, 0.0};
    }

    q[0] /= norm;
    q[1] /= norm;
    q[2] /= norm;
    q[3] /= norm;
    return q;
}

QVariantList CameraCalculator::calculatePosStd(
    double targetX,
    double targetY,
    double altitudeMeters
) const
{
    if (altitudeMeters <= 0.0) {
        return {MIN_POS_STD_M, MIN_POS_STD_M, MIN_POS_STD_M};
    }

    double forwardMeters = 0.0;
    double rightMeters = 0.0;
    imageToBodyFrdMeters(targetX, targetY, altitudeMeters, forwardMeters, rightMeters);

    const double halfHFov = qDegreesToRadians(HORIZONTAL_FOV_DEG / 2.0);
    const double halfVFov = qDegreesToRadians(VERTICAL_FOV_DEG / 2.0);
    const double metersPerPixelX = altitudeMeters * qTan(halfHFov) / (IMAGE_WIDTH / 2.0);
    const double metersPerPixelY = altitudeMeters * qTan(halfVFov) / (IMAGE_HEIGHT / 2.0);
    const double range = qSqrt(altitudeMeters * altitudeMeters + forwardMeters * forwardMeters + rightMeters * rightMeters);
    const double rangeScale = range / altitudeMeters;

    const double sigmaForward = qMax(MIN_POS_STD_M, metersPerPixelY * CLICK_SIGMA_PIXELS * rangeScale);
    const double sigmaRight = qMax(MIN_POS_STD_M, metersPerPixelX * CLICK_SIGMA_PIXELS * rangeScale);
    const double sigmaDown = qMax(MIN_POS_STD_M, ALTITUDE_STD_BIAS_M + ALTITUDE_STD_FRACTION * altitudeMeters);

    return {sigmaForward, sigmaRight, sigmaDown};
}

double CameraCalculator::calculateYawStd(
    double /*targetX*/,
    double /*targetY*/,
    double altitudeMeters
) const
{
    // A click is not a fiducial heading observation; keep yaw loosely constrained.
    if (altitudeMeters <= 0.0) {
        return MIN_YAW_STD_RAD;
    }

    const double halfHFov = qDegreesToRadians(HORIZONTAL_FOV_DEG / 2.0);
    const double pixelYaw = qTan(halfHFov) / (IMAGE_WIDTH / 2.0) * CLICK_SIGMA_PIXELS;
    return qMax(MIN_YAW_STD_RAD, pixelYaw);
}

QVariantMap CameraCalculator::calculateTargetRelative(
    double targetX,
    double targetY,
    double altitudeMeters,
    double rollDegrees,
    double pitchDegrees,
    double yawDegrees
) const
{
    double forwardMeters = 0.0;
    double rightMeters = 0.0;
    imageToBodyFrdMeters(targetX, targetY, altitudeMeters, forwardMeters, rightMeters);

    const std::array<double, 4> qSensor = bodyToNedQuaternion(rollDegrees, pitchDegrees, yawDegrees);
    // q_in_ned = q_sensor * q_target. A level north-aligned ground target needs q_in_ned = identity,
    // so q_target is the conjugate of the body-to-NED attitude.
    const QVariantList qTarget = quaternionToVariantList({qSensor[0], -qSensor[1], -qSensor[2], -qSensor[3]});

    return {
        {QStringLiteral("forwardMeters"), forwardMeters},
        {QStringLiteral("rightMeters"), rightMeters},
        {QStringLiteral("posStd"), calculatePosStd(targetX, targetY, altitudeMeters)},
        {QStringLiteral("yawStd"), calculateYawStd(targetX, targetY, altitudeMeters)},
        {QStringLiteral("qTarget"), qTarget},
        {QStringLiteral("qSensor"), quaternionToVariantList(qSensor)},
    };
}
