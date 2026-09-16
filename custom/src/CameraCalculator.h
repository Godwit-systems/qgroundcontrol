#pragma once

#include <QObject> 
#include <QGeoCoordinate>

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

    
};

