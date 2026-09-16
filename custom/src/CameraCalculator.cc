#include "CameraCalculator.h"

#include <QtMath>

namespace
{
    constexpr double IMAGE_WIDTH  = 3088.0;
    constexpr double IMAGE_HEIGHT = 2076.0;

    constexpr double HORIZONTAL_FOV_DEG = 25.4;
    constexpr double VERTICAL_FOV_DEG   = 17.7;
}

CameraCalculator::CameraCalculator(QObject *parent)
    : QObject(parent)
{
}

double CameraCalculator::calculateGroundDistance(
    double targetX,
    double targetY,
    double altitudeMeters
) const
{
    if (altitudeMeters <= 0.0) {
        return 0.0;
    }

    // Image center
    const double cx = IMAGE_WIDTH  / 2.0;
    const double cy = IMAGE_HEIGHT / 2.0;

    // Normalized position relative to image center.
    //
    // -1 = left/top edge
    //  0 = center
    // +1 = right/bottom edge
    const double nx = (targetX - cx) / cx;
    const double ny = (targetY - cy) / cy;

    // Half FOV in radians
    const double halfHFov =
        qDegreesToRadians(HORIZONTAL_FOV_DEG / 2.0);

    const double halfVFov =
        qDegreesToRadians(VERTICAL_FOV_DEG / 2.0);

    // Angle of the camera ray away from the optical axis.
    //
    // For a pinhole camera:
    //
    // tan(angleX) = nx * tan(horizontalHalfFOV)
    // tan(angleY) = ny * tan(verticalHalfFOV)
    //
    // This gives the ground displacement at the given altitude.

    const double groundX =
        altitudeMeters *
        nx *
        qTan(halfHFov);

    const double groundY =
        altitudeMeters *
        ny *
        qTan(halfVFov);

    return qSqrt(
        groundX * groundX +
        groundY * groundY
    );
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

    const double groundDistance =
        calculateGroundDistance(
            targetX,
            targetY,
            altitudeMeters
        );

    return qSqrt(
        altitudeMeters * altitudeMeters +
        groundDistance * groundDistance
    );
}

double CameraCalculator::calculateTimeInSeconds(
    double altitudeMeters
) const
{
    if (altitudeMeters <= 0.0) {
        return 0.0;
    }
    return qSqrt(
        (2 * altitudeMeters) / 9.81
    );
}

QGeoCoordinate CameraCalculator::calculateTargetCoordinate(
    double targetX,
    double targetY,
    double altitudeMeters,
    const QGeoCoordinate &droneCoordinate,
    double headingDegrees
) const
{
    if (altitudeMeters <= 0.0 || !droneCoordinate.isValid()) {
        return QGeoCoordinate();
    }

    const double cx = IMAGE_WIDTH  / 2.0;
    const double cy = IMAGE_HEIGHT / 2.0;

    const double nx = (targetX - cx) / cx;
    const double ny = (targetY - cy) / cy;

    const double halfHFov = qDegreesToRadians(HORIZONTAL_FOV_DEG / 2.0);
    const double halfVFov = qDegreesToRadians(VERTICAL_FOV_DEG / 2.0);

    const double rightOffset =
        altitudeMeters * nx * qTan(halfHFov);

    const double forwardOffset =
        -altitudeMeters * ny * qTan(halfVFov);

    const double groundDistance =
        calculateGroundDistance(targetX, targetY, altitudeMeters);

    const double relativeBearingDeg =
        qRadiansToDegrees(qAtan2(rightOffset, forwardOffset));

    double absoluteBearingDeg =
        std::fmod(headingDegrees + relativeBearingDeg + 360.0, 360.0);

    return droneCoordinate.atDistanceAndAzimuth(groundDistance, absoluteBearingDeg);
}