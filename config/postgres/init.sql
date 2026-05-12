-- PG accessory가 최초 기동될 때(POSTGRES_DB로 blackticket_production만 만들어지므로)
-- Solid Cache/Queue/Cable이 쓰는 분리된 데이터베이스를 함께 생성한다.
-- docker-entrypoint-initdb.d/는 데이터 디렉터리가 비어 있는 첫 부팅에만 실행됨.
CREATE DATABASE blackticket_production_cache OWNER blackticket;
CREATE DATABASE blackticket_production_queue OWNER blackticket;
CREATE DATABASE blackticket_production_cable OWNER blackticket;
