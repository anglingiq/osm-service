CREATE OR REPLACE FUNCTION find_nearest_waterways(lat double precision, lon double precision, inset numeric default 0.1) 
RETURNS TABLE (
	id bigint,
	the_name text,
	latitude double precision,
	longitude double precision,
	centerLat double precision,
	centerLon double precision) AS $$ 
BEGIN

RETURN QUERY
SELECT
		osm_id as id,
		name as the_name,
       	ST_Y((dp).geom) AS latitude,
       	ST_X((dp).geom) AS longitude,
       	ST_Y(ST_ClosestPoint(way, ST_Centroid(way))) AS centerLat,
       	ST_X(ST_ClosestPoint(way, ST_Centroid(way))) AS centerLon
FROM
  (SELECT way,
  		  ST_DumpPoints(way) AS dp,
          name,
          osm_id
   FROM planet_osm_line
   WHERE (way && ST_MakeEnvelope(lon - inset, lat - inset, lon + inset, lat + inset, 4326)) AND waterway='river' AND name IS NOT NULL) AS blertz;
 END;
 $$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION find_nearest_waters(lat double precision, lon double precision, inset numeric default 0.1) 
RETURNS TABLE (
	id bigint,
	the_name text,
	latitude double precision,
	longitude double precision) AS $$ 
BEGIN

RETURN QUERY
SELECT
		osm_id as id,
		name as the_name,
       	ST_Y((dp).geom) AS latitude,
       	ST_X((dp).geom) AS longitude
       
FROM
  (SELECT ST_DumpPoints(way) AS dp,
          name,
          osm_id
   FROM planet_osm_polygon
   WHERE (way && ST_MakeEnvelope(lon - inset, lat - inset, lon + inset, lat + inset, 4326)) AND 'waterway'='water') AS blertz;
 END;
 $$ LANGUAGE plpgsql;

