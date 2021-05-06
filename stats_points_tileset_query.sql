DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_stats_usa_tileset_temp`;
CALL bqcarto.tiler.CREATE_POINT_AGGREGATION_TILESET(
R'''(
    SELECT 
    0 as zoom_min,
    6 as zoom_max,
    pop,
    fully_vacc,
    pop - fully_vacc AS non_vacc,
    0 AS unknown,
    geom
    FROM `cartobq.maps.data_by_state`

    UNION ALL

    SELECT 
    7 as zoom_min,
    14 as zoom_max,
    1 as pop,
    IF(vaccinated = 'true', 1, 0) AS fully_vacc,
    IF(vaccinated = 'false', 1, 0) AS non_vacc,
    IF(vaccinated = 'unknown', 1, 0) AS unknown,
    geom
    FROM `cartobq.maps.covid19_vaccinated_usa_blockgroups_100pct`
)''',
'`cartobq.maps.covid19_vaccinated_stats_usa_tileset_temp`',
R'''
    {
    "zoom_min": 0,
    "zoom_max": 14,
    "zoom_min_column": "zoom_min",
    "zoom_max_column": "zoom_max",
    "aggregation_type": "quadkey",
    "aggregation_resolution": 6,
    "aggregation_placement": "features-centroid",
    "properties":{
        "aggregated_total": {
        "formula":"sum(pop)",
        "type":"Number"
        },
        "vaccinated": {
        "formula":"SUM(fully_vacc)",
        "type":"Number"
        },
        "non_vaccinated": {
        "formula":"SUM(non_vacc)",
        "type":"Number"
        },
        "unknown": {
        "formula":"SUM(unknown)",
        "type":"Number"
        }
    }
    }
'''
);

-- Allocate the tileset in its final table
--DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_stats_usa_tileset`;
--CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_stats_usa_tileset` AS 
--SELECT * FROM `cartobq.maps.covid19_vaccinated_stats_usa_tileset_temp`;
--DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_stats_usa_tileset_temp`;
