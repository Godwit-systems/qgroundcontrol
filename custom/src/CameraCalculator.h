#pragma once

#include <array>

#include <QGeoCoordinate>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class CameraCalculator : public QObject
{
    Q_OBJECT

public:
    explicit CameraCalculator(QObject *parent = nullptr);

    Q_INVOKABLE double calculateGroundDistance(
        double targetX,
        double targetY,
        double altitudeMeters
    ) const;

    Q_INVOKABLE double calculateDistanceToTarget(
        double targetX,
        double targetY,
        double altitudeMeters
    ) const;

    Q_INVOKABLE double calculateTimeInSeconds(
        double altitudeMeters
    ) const;

    Q_INVOKABLE QGeoCoordinate calculateTargetCoordinate(
        double targetX,
        double targetY,
        double altitudeMeters,
        const QGeoCoordinate &droneCoordinate,
        double headingDegrees
    ) const;

    /// BODY_FRD click observation: forwardMeters, rightMeters, posStd, yawStd, qTarget, qSensor.
    Q_INVOKABLE QVariantMap calculateTargetRelative(
        double targetX,
        double targetY,
        double altitudeMeters,
        double rollDegrees,
        double pitchDegrees,
        double yawDegrees
    ) const;

private:
    void imageToBodyFrdMeters(
        double targetX,
        double targetY,
        double altitudeMeters,
        double &forwardMeters,
        double &rightMeters
    ) const;

    QVariantList calculatePosStd(
        double targetX,
        double targetY,
        double altitudeMeters
    ) const;

    double calculateYawStd(
        double targetX,
        double targetY,
        double altitudeMeters
    ) const;

    std::array<double, 4> bodyToNedQuaternion(
        double rollDegrees,
        double pitchDegrees,
        double yawDegrees
    ) const;
};
