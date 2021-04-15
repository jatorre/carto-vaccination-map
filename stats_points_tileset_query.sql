DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_stats_usa_tileset_temp`;
CALL bqcarto.tiler.CREATE_POINT_AGGREGATION_TILESET(
R'''(
    SELECT * FROM `cartobq.maps.covid19_vaccinated_usa_blockgroups_100pct`
)''',
'`cartobq.maps.covid19_vaccinated_stats_usa_tileset_temp`',
R'''
    {
    "zoom_min": 0,
    "zoom_max": 14,
    "aggregation_type": "quadkey",
    "aggregation_resolution": 6,
    "aggregation_placement": "features-centroid",
    "properties":{
        "aggregated_total": {
        "formula":"count(*)",
        "type":"Number"
        },
        "vaccinated": {
        "formula":"SUM(IF(vaccinated = 'true', 1, 0))",
        "type":"Number"
        },
        "non_vaccinated": {
        "formula":"SUM(IF(vaccinated = 'false', 1, 0))",
        "type":"Number"
        },
        "unknown": {
        "formula":"SUM(IF(vaccinated = 'unknown', 1, 0))",
        "type":"Number"
        }
    }
    }
'''
    );

-- Allocate the tileset in its final table
CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_stats_usa_tileset` AS 
SELECT * FROM `cartobq.maps.covid19_vaccinated_stats_usa_tileset_temp`;
DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_stats_usa_tileset_temp`;