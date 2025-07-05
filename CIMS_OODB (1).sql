-- Domains
CREATE DOMAIN email_address AS VARCHAR(255)
    CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
CREATE DOMAIN phone_number AS VARCHAR(20)
    CHECK (VALUE ~ '^\+?[0-9\s\-\(\)]+$');
CREATE DOMAIN positive_decimal AS DECIMAL(12,2)
    CHECK (VALUE >= 0);
CREATE DOMAIN positive_integer AS INTEGER
    CHECK (VALUE >= 0);
CREATE DOMAIN year_domain AS INTEGER
    CHECK (VALUE > 1900 AND value <= EXTRACT(YEAR FROM CURRENT_DATE));

-- Types
CREATE TYPE vehicle_status_type AS ENUM ('in_stock', 'sold', 'maintenance', 'reserved');
CREATE TYPE fuel_type AS ENUM ('gasoline', 'diesel', 'electric', 'hybrid', 'plugin_hybrid');
CREATE TYPE transmission_type AS ENUM ('automatic', 'manual', 'cvt', 'dct');
CREATE TYPE payment_method_type AS ENUM ('cash', 'finance', 'lease', 'credit');
CREATE TYPE luxury_level_type AS ENUM ('standard', 'luxury', 'premium', 'ultra');
CREATE TYPE cab_type AS ENUM ('regular', 'extended', 'crew');
CREATE TYPE user_role_type AS ENUM ('admin', 'sales', 'inventory', 'readonly');
CREATE TYPE address_type AS (
                                street_address1 VARCHAR(100),
                                street_address2 VARCHAR(100),
                                city VARCHAR(50),
                                state VARCHAR(50),
                                postal_code VARCHAR(20),
                                country VARCHAR(50),
                                address_type VARCHAR(20)
                            );

-- Base Vehicle class
CREATE TABLE vehicles (
                          vehicle_id VARCHAR(50) PRIMARY KEY,
                          make VARCHAR(100) NOT NULL,
                          model VARCHAR(100) NOT NULL,
                          year year_domain,
                          vin VARCHAR(17) UNIQUE NOT NULL,
                          purchase_price positive_decimal NOT NULL,
                          price positive_decimal,
                          date_acquired DATE NOT NULL DEFAULT CURRENT_DATE,
                          status vehicle_status_type NOT NULL DEFAULT 'in_stock',
                          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                          updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Car subclass (inherits from vehicles)
CREATE TABLE cars (
                      car_id VARCHAR(50),
                      body_type VARCHAR(50) NOT NULL,
                      fuel_type fuel_type NOT NULL,
                      transmission transmission_type NOT NULL,
                      mileage positive_integer NOT NULL DEFAULT 0,
                      engine_size DECIMAL(3, 1),
                      PRIMARY KEY (vehicle_id)
) INHERITS (vehicles);

-- Sedan subclass (inherits from cars)
CREATE TABLE sedans (
                        sedan_id VARCHAR(50),
                        luxury_level luxury_level_type,
                        PRIMARY KEY (vehicle_id)
) INHERITS (cars);

-- SUV subclass (inherits from cars)
CREATE TABLE suvs (
                      suv_id VARCHAR(50),
                      seating_capacity positive_integer CHECK (seating_capacity > 0),
                      cargo_capacity DECIMAL(6, 2),
                      ground_clearance DECIMAL(4, 1),
                      awd_4wd BOOLEAN DEFAULT FALSE,
                      PRIMARY KEY (vehicle_id)
) INHERITS (cars);

-- Truck subclass (inherits from cars)
CREATE TABLE trucks (
                        truck_id VARCHAR(50),
                        bed_length DECIMAL(5, 2),
                        towing_capacity positive_integer,
                        payload_capacity positive_integer,
                        cab_type cab_type,
                        PRIMARY KEY (vehicle_id)
) INHERITS (cars);

-- Parts inventory
CREATE TABLE parts (
                       part_id VARCHAR(50) PRIMARY KEY,
                       name VARCHAR(100) NOT NULL,
                       description TEXT,
                       category VARCHAR(50) NOT NULL,
                       part_number VARCHAR(50) UNIQUE NOT NULL,
                       price DECIMAL(10, 2) NOT NULL,
                       quantity_in_stock positive_integer NOT NULL DEFAULT 0,
                       reorder_threshold positive_integer NOT NULL DEFAULT 5,
                       reorder_quantity positive_integer NOT NULL DEFAULT 10,
                       supplier_id VARCHAR(50),
                       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Vehicle parts relationship
CREATE TABLE vehicle_parts (
                               vehicle_id VARCHAR(50),
                               part_id VARCHAR(50) REFERENCES parts(part_id) ON DELETE RESTRICT,
                               quantity positive_integer NOT NULL DEFAULT 1,
                               installed_date DATE DEFAULT CURRENT_DATE,
                               PRIMARY KEY (vehicle_id, part_id)
);

-- Customers
CREATE TABLE customers (
                           customer_id VARCHAR(50) PRIMARY KEY,
                           username VARCHAR(50) UNIQUE,
                           first_name VARCHAR(50) NOT NULL,
                           last_name VARCHAR(50) NOT NULL,
                           email email_address UNIQUE,
                           phone phone_number,
                           password_hash VARCHAR(255) NOT NULL,
                           is_active BOOLEAN NOT NULL DEFAULT TRUE,
                           created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                           updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Sales table
CREATE TABLE sales (
                       sale_id VARCHAR(50) PRIMARY KEY,
                       vehicle_id VARCHAR(50),
                       customer_id VARCHAR(50) REFERENCES customers(customer_id) ON DELETE RESTRICT,
                       sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
                       sale_price DECIMAL(12, 2) NOT NULL,
                       payment_method payment_method_type NOT NULL,
                       finance_term positive_integer,
                       notes TEXT,
                       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);



-- Security: Row-Level Security
-- Enable Row Level Security on vehicles
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cars ENABLE ROW LEVEL SECURITY;
ALTER TABLE sedans ENABLE ROW LEVEL SECURITY;
ALTER TABLE suvs ENABLE ROW LEVEL SECURITY;
ALTER TABLE trucks ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can see and modify all
CREATE POLICY admin_vehicles_policy ON vehicles
    TO car_admin
    USING (TRUE)
    WITH CHECK (TRUE);

-- Sales can see all but only modify non-sold vehicles
CREATE POLICY sales_vehicles_view_policy ON vehicles
    TO car_sales
    USING (TRUE);

CREATE POLICY sales_vehicles_modify_policy ON vehicles
    TO car_sales
    USING (status != 'sold')
    WITH CHECK (status != 'sold');

-- Inventory staff can see all and modify inventory-related fields
CREATE POLICY inventory_vehicles_policy ON vehicles
    TO car_inventory
    USING (TRUE)
    WITH CHECK (TRUE);

-- Readonly role can only view data
CREATE POLICY readonly_vehicles_policy ON vehicles
    TO car_readonly
    USING (TRUE);

-- Policies for cars table
CREATE POLICY admin_cars_policy ON cars
    TO car_admin
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY sales_cars_view_policy ON cars
    TO car_sales
    USING (TRUE);

CREATE POLICY sales_cars_modify_policy ON cars
    TO car_sales
    USING (status != 'sold')
    WITH CHECK (status != 'sold');

CREATE POLICY inventory_cars_policy ON cars
    TO car_inventory
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY readonly_cars_policy ON cars
    TO car_readonly
    USING (TRUE);

-- Policies for sedans table
CREATE POLICY admin_sedans_policy ON sedans
    TO car_admin
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY sales_sedans_view_policy ON sedans
    TO car_sales
    USING (TRUE);

CREATE POLICY sales_sedans_modify_policy ON sedans
    TO car_sales
    USING (status != 'sold')
    WITH CHECK (status != 'sold');

CREATE POLICY inventory_sedans_policy ON sedans
    TO car_inventory
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY readonly_sedans_policy ON sedans
    TO car_readonly
    USING (TRUE);

-- Policies for suvs table
CREATE POLICY admin_suvs_policy ON suvs
    TO car_admin
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY sales_suvs_view_policy ON suvs
    TO car_sales
    USING (TRUE);

CREATE POLICY sales_suvs_modify_policy ON suvs
    TO car_sales
    USING (status != 'sold')
    WITH CHECK (status != 'sold');

CREATE POLICY inventory_suvs_policy ON suvs
    TO car_inventory
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY readonly_suvs_policy ON suvs
    TO car_readonly
    USING (TRUE);

-- Policies for trucks table
CREATE POLICY admin_trucks_policy ON trucks
    TO car_admin
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY sales_trucks_view_policy ON trucks
    TO car_sales
    USING (TRUE);

CREATE POLICY sales_trucks_modify_policy ON trucks
    TO car_sales
    USING (status != 'sold')
    WITH CHECK (status != 'sold');

CREATE POLICY inventory_trucks_policy ON trucks
    TO car_inventory
    USING (TRUE)
    WITH CHECK (TRUE);

CREATE POLICY readonly_trucks_policy ON trucks
    TO car_readonly
    USING (TRUE);

-- Create indexes for performance
CREATE INDEX idx_vehicles_status ON vehicles(status);
CREATE INDEX idx_cars_make_model ON cars(make, model);
CREATE INDEX idx_parts_category ON parts(category);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sedans_sedan_id ON sedans(sedan_id);
CREATE INDEX idx_suvs_suv_id ON suvs(suv_id);
CREATE INDEX idx_trucks_truck_id ON trucks(truck_id);

-- Add unique constraints for subclass IDs
ALTER TABLE sedans ADD CONSTRAINT sedans_sedan_id_key UNIQUE (sedan_id);
ALTER TABLE suvs ADD CONSTRAINT suvs_suv_id_key UNIQUE (suv_id);
ALTER TABLE trucks ADD CONSTRAINT trucks_truck_id_key UNIQUE (truck_id);

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO car_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO car_admin;

-- Sales Role Permissions (Customer and Sales focused)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO car_sales;
GRANT INSERT, UPDATE ON
    vehicles, cars, sedans, suvs, trucks,
    customers,sales
    TO car_sales;

-- Inventory Role Permissions (Vehicle and Parts focused)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO car_inventory;
GRANT INSERT, UPDATE ON
    vehicles, cars, sedans, suvs, trucks,
    parts, vehicle_parts TO car_inventory;
-- Read-only Role Permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO car_readonly;

-- Revoke critical operations from non-admin roles
REVOKE DELETE ON vehicles, cars, sedans, suvs, trucks, sales, customers FROM car_sales;
REVOKE INSERT, UPDATE, DELETE ON customers, sales FROM car_inventory;

-- Grant usage on sequences for ID generation
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO car_sales, car_inventory;


-- Create roles for security
CREATE ROLE car_admin WITH LOGIN PASSWORD 'admin_pass';
CREATE ROLE car_sales WITH LOGIN PASSWORD 'sales_pass';
CREATE ROLE car_inventory WITH LOGIN PASSWORD 'inventory_pass';
CREATE ROLE car_readonly WITH LOGIN PASSWORD 'readonly_pass';

-- Create users and assign roles
CREATE USER Omar WITH PASSWORD 'baherjr';
CREATE USER salesperson WITH PASSWORD 'sales';
CREATE USER inventory_manager WITH PASSWORD 'inv';
CREATE USER reporting_and_audit WITH PASSWORD 'audit';

GRANT car_admin TO Omar;
GRANT car_sales TO salesperson;
GRANT car_inventory TO inventory_manager;
GRANT car_readonly TO reporting_and_audit;


-- Create rules to route inserts to the appropriate fragment
CREATE RULE vehicles_insert_in_stock AS
    ON INSERT TO vehicles
    WHERE (NEW.status = 'in_stock')
    DO INSTEAD
    INSERT INTO vehicles_in_stock VALUES (NEW.*);

CREATE RULE vehicles_insert_sold AS
    ON INSERT TO vehicles
    WHERE (NEW.status = 'sold')
    DO INSTEAD
    INSERT INTO vehicles_sold VALUES (NEW.*);

CREATE RULE vehicles_insert_maintenance AS
    ON INSERT TO vehicles
    WHERE (NEW.status = 'maintenance')
    DO INSTEAD
    INSERT INTO vehicles_maintenance VALUES (NEW.*);


-- Horizontal Fragmentation

CREATE TABLE vehicles_in_stock (
                                   CHECK (status = 'in_stock')
) INHERITS (vehicles);

CREATE TABLE vehicles_sold (
                               CHECK (status = 'sold')
) INHERITS (vehicles);

CREATE TABLE vehicles_maintenance (
                                      CHECK (status = 'maintenance')
) INHERITS (vehicles);

-- Vertical Fragmentation
-- We fragmented this table to the following
-- CREATE TABLE service_records (
--                                  service_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--                                  vehicle_id UUID REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
--                                  service_date DATE NOT NULL DEFAULT CURRENT_DATE,
--                                  description TEXT NOT NULL,
--                                  cost DECIMAL(10, 2) NOT NULL,
--                                  technician_name VARCHAR(100),
--                                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
--                                  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );

CREATE TABLE service_basic_info (
                                    service_id varchar(50) PRIMARY KEY,
                                    vehicle_id varchar(50),
                                    service_date DATE NOT NULL,
                                    description TEXT NOT NULL,
                                    created_at TIMESTAMP NOT NULL,
                                    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE service_cost_info (
                                   service_id varchar(50) PRIMARY KEY REFERENCES service_basic_info(service_id),
                                   cost DECIMAL(10, 2) NOT NULL
);

CREATE TABLE service_technician_info (
                                         service_id varchar(50) PRIMARY KEY REFERENCES service_basic_info(service_id),
                                         technician_name VARCHAR(100)
);

-- Assume vehicle_id is the identifier for the vehicle you want to update (Atomicity)
BEGIN;

DO $$
    DECLARE
        vehicle_record RECORD;
    BEGIN
        -- Retrieve the vehicle record from vehicles_in_stock
        SELECT * INTO vehicle_record FROM vehicles_in_stock WHERE vehicle_id = 'your-vehicle-id'; -- Replace with your vehicle ID

        -- Insert the record into vehicles_sold with the updated status
        INSERT INTO vehicles_sold (vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status, created_at, updated_at)
        VALUES (vehicle_record.vehicle_id, vehicle_record.make, vehicle_record.model, vehicle_record.year, vehicle_record.vin,
                vehicle_record.purchase_price, vehicle_record.price, vehicle_record.date_acquired, 'sold', vehicle_record.created_at, CURRENT_TIMESTAMP);

        -- Delete the record from vehicles_in_stock
        DELETE FROM vehicles_in_stock WHERE vehicle_id = 'your-vehicle-id'; -- Replace with your vehicle ID
    END $$;

COMMIT;


-- Insert with ROLLBACK on Error
-- Insert a New Vehicle with Error Handling
DO $$
    BEGIN
        -- Start of the transaction block
        BEGIN
            -- Insert a new vehicle into the vehicles table
            INSERT INTO vehicles (make, model, year, vin, purchase_price, price, status)
            VALUES ('Toyota', 'Camry', 2023, '1HGCM82633A004352', 25000.00, 28000.00, 'in_stock');

            -- Simulate an error by attempting to insert a duplicate VIN
            INSERT INTO vehicles (make, model, year, vin, purchase_price, price, status)
            VALUES ('Toyota', 'Camry', 2023, '1HGCM82633A004352', 25000.00, 28000.00, 'in_stock');

        EXCEPTION
            WHEN unique_violation THEN
                RAISE NOTICE 'Transaction rolled back due to unique constraint violation';
                RETURN;
            WHEN others THEN
                RAISE NOTICE 'Transaction rolled back due to an error: %', SQLERRM;
                RETURN;
        END;
    END $$;



-- Savepoints for Partial Rollback
-- Using Savepoints to Rollback Part of a Transaction

DO $$
    BEGIN
        BEGIN;

        -- Update the status of a vehicle from 'in_stock' to 'sold'
        UPDATE vehicles
        SET status = 'sold', updated_at = CURRENT_TIMESTAMP
        WHERE vehicle_id = '1HGCM82633A004352';

        -- Simulate an error by attempting to update a non-existent vehicle
        UPDATE vehicles
        SET status = 'sold', updated_at = CURRENT_TIMESTAMP
        WHERE vehicle_id = 'NON_EXISTENT_VIN';

        COMMIT;

        EXCEPTION
            WHEN others THEN
                ROLLBACK;
                RAISE NOTICE 'Transaction rolled back due to an error';
        END;
    END $$;

-- INSERT statements for vehicles table (base table) - 60 vehicles total
INSERT INTO vehicles (vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status)
VALUES
-- Toyota vehicles
('V1001', 'Toyota', 'Corolla', 2022, 'JT2BF22K1X0123456', 18500.00, 21999.99, '2023-01-15', 'in_stock'),
('V1002', 'Toyota', 'Camry', 2022, '4T1BF1FK5NU123457', 24500.00, 28999.99, '2023-01-16', 'in_stock'),
('V1003', 'Toyota', 'RAV4', 2023, '2T3F1RFV8MW123458', 28000.00, 32999.99, '2023-01-18', 'in_stock'),
('V1004', 'Toyota', 'Highlander', 2022, '5TDKZRFH1NS123459', 35000.00, 39999.99, '2023-01-20', 'sold'),
('V1005', 'Toyota', 'Tacoma', 2023, '3TMCZ5AN9PM123460', 32000.00, 37999.99, '2023-01-22', 'in_stock'),
('V1006', 'Toyota', 'Tundra', 2022, '5TFHY5F10NX123461', 42000.00, 48999.99, '2023-01-25', 'sold'),
('V1007', 'Toyota', 'Sienna', 2022, '5TDKZ3DC2NS123462', 34000.00, 39999.99, '2023-01-27', 'maintenance'),
('V1008', 'Toyota', 'Avalon', 2021, '4T1BZ1FB3MU123463', 32000.00, 36999.99, '2023-01-30', 'in_stock'),

-- Honda vehicles
('V1009', 'Honda', 'Civic', 2022, '2HGFE2F53NH123464', 21000.00, 24999.99, '2023-02-01', 'in_stock'),
('V1010', 'Honda', 'Accord', 2022, '1HGCV2F34NA123465', 25000.00, 29999.99, '2023-02-03', 'sold'),
('V1011', 'Honda', 'CR-V', 2023, '7FARW2H58PE123466', 28500.00, 33999.99, '2023-02-05', 'in_stock'),
('V1012', 'Honda', 'Pilot', 2022, '5FNYF8H91NB123467', 36000.00, 41999.99, '2023-02-08', 'in_stock'),
('V1013', 'Honda', 'Odyssey', 2022, '5FNRL6H75NB123468', 33000.00, 38999.99, '2023-02-10', 'sold'),
('V1014', 'Honda', 'HR-V', 2023, '3CZRU6H73PM123469', 23000.00, 27999.99, '2023-02-12', 'in_stock'),
('V1015', 'Honda', 'Ridgeline', 2022, '5FPYK3F79NB123470', 35000.00, 40999.99, '2023-02-15', 'in_stock'),

-- Ford vehicles
('V1016', 'Ford', 'F-150', 2023, '1FTFW1ET3DFA12345', 38000.00, 44999.99, '2023-02-18', 'in_stock'),
('V1017', 'Ford', 'Escape', 2022, '1FMCU9G69NU123471', 25000.00, 29999.99, '2023-02-20', 'sold'),
('V1018', 'Ford', 'Explorer', 2023, '1FM5K8JT1PGA12347', 36000.00, 42999.99, '2023-02-22', 'in_stock'),
('V1019', 'Ford', 'Mustang', 2022, '1FA6P8TH2N5123472', 39000.00, 45999.99, '2023-02-25', 'in_stock'),
('V1020', 'Ford', 'Edge', 2022, '2FMPK4J98NB123473', 32000.00, 37999.99, '2023-02-27', 'maintenance'),
('V1021', 'Ford', 'Bronco', 2023, '1FMEE5DP7PL123474', 42000.00, 48999.99, '2023-03-01', 'in_stock'),
('V1022', 'Ford', 'Ranger', 2022, '1FTER4FH2NL123475', 29000.00, 34999.99, '2023-03-03', 'in_stock'),

-- Chevrolet vehicles
('V1023', 'Chevrolet', 'Silverado', 2023, '3GCUYEED9PG123476', 40000.00, 46999.99, '2023-03-05', 'in_stock'),
('V1024', 'Chevrolet', 'Equinox', 2022, '2GNFLFEK8D6123456', 24500.00, 28999.99, '2023-03-07', 'sold'),
('V1025', 'Chevrolet', 'Tahoe', 2022, '1GNSKCKD3NR123477', 48000.00, 55999.99, '2023-03-10', 'in_stock'),
('V1026', 'Chevrolet', 'Traverse', 2023, '1GNEVKKW1PJ123478', 34000.00, 39999.99, '2023-03-12', 'in_stock'),
('V1027', 'Chevrolet', 'Malibu', 2022, '1G1ZD5ST9NF123479', 22000.00, 26999.99, '2023-03-15', 'sold'),
('V1028', 'Chevrolet', 'Blazer', 2022, '3GNKBKRS9NS123480', 31000.00, 36999.99, '2023-03-17', 'in_stock'),

-- Luxury brands
('V1029', 'BMW', '3 Series', 2022, 'WBA3N5C51EK123456', 41000.00, 47500.00, '2023-03-20', 'in_stock'),
('V1030', 'BMW', '5 Series', 2023, 'WBA13AL01PCF12348', 52000.00, 59999.99, '2023-03-22', 'in_stock'),
('V1031', 'BMW', 'X3', 2022, '5UXTY5C06N9123481', 44000.00, 50999.99, '2023-03-25', 'sold'),
('V1032', 'BMW', 'X5', 2023, '5UXCR6C06P9123482', 58000.00, 65999.99, '2023-03-27', 'in_stock'),
('V1033', 'Mercedes-Benz', 'C-Class', 2022, '55SWF8EB1NU123483', 43000.00, 49999.99, '2023-03-30', 'in_stock'),
('V1034', 'Mercedes-Benz', 'E-Class', 2021, 'WDDZF4JB1KA123456', 52000.00, 58999.99, '2023-04-01', 'sold'),
('V1035', 'Mercedes-Benz', 'GLC', 2023, 'W1N0G8EB9PF123484', 48000.00, 55999.99, '2023-04-03', 'in_stock'),
('V1036', 'Mercedes-Benz', 'GLE', 2022, 'W1N0G8DB4NM123485', 58000.00, 66999.99, '2023-04-05', 'maintenance'),
('V1037', 'Audi', 'A4', 2023, 'WAUENAF46JN123456', 43000.00, 49999.99, '2023-04-08', 'in_stock'),
('V1038', 'Audi', 'Q5', 2022, 'WA1BNAFY7N2123486', 46000.00, 53999.99, '2023-04-10', 'in_stock'),
('V1039', 'Audi', 'A6', 2023, 'WAUE8AF27PN123487', 54000.00, 61999.99, '2023-04-12', 'sold'),
('V1040', 'Audi', 'Q7', 2022, 'WA1VAAF79ND123488', 59000.00, 67999.99, '2023-04-15', 'in_stock'),

-- Electric/Hybrid vehicles
('V1041', 'Tesla', 'Model 3', 2023, '5YJ3E1EA1PF123456', 42000.00, 48999.99, '2023-04-17', 'in_stock'),
('V1042', 'Tesla', 'Model Y', 2022, '5YJYGDEE9NF123489', 48000.00, 54999.99, '2023-04-20', 'sold'),
('V1043', 'Tesla', 'Model S', 2022, '5YJSA1E44NF123490', 75000.00, 84999.99, '2023-04-22', 'in_stock'),
('V1044', 'Toyota', 'Prius', 2023, 'JTDKAMFP4P3123491', 28000.00, 32999.99, '2023-04-25', 'in_stock'),
('V1045', 'Hyundai', 'IONIQ 5', 2022, 'KM8KR4AE4NU123492', 39000.00, 45999.99, '2023-04-27', 'sold'),
('V1046', 'Kia', 'EV6', 2023, 'KNDCR3LD4P5123493', 41000.00, 47999.99, '2023-04-30', 'in_stock'),

-- Other popular brands
('V1047', 'Jeep', 'Grand Cherokee', 2022, '1C4RJFAG2CC123456', 39500.00, 46999.99, '2023-05-02', 'in_stock'),
('V1048', 'Jeep', 'Wrangler', 2023, '1C4HJXEG5PS123494', 41000.00, 47999.99, '2023-05-05', 'sold'),
('V1049', 'Ram', '1500', 2022, '1C6RR7LG8LS123456', 39000.00, 45500.00, '2023-05-07', 'in_stock'),
('V1050', 'Ram', '2500', 2023, '3C6UR5FL4PG123495', 48000.00, 55999.99, '2023-05-10', 'in_stock'),
('V1051', 'Subaru', 'Outback', 2022, '4S4BTGPD6N3123496', 29000.00, 34999.99, '2023-05-12', 'sold'),
('V1052', 'Subaru', 'Forester', 2023, 'JF2SKAUC7P8123497', 28000.00, 33999.99, '2023-05-15', 'in_stock'),
('V1053', 'Nissan', 'Altima', 2022, '1N4BL4EV3NC123498', 23000.00, 27999.99, '2023-05-17', 'in_stock'),
('V1054', 'Nissan', 'Rogue', 2023, 'JN8AT3BB4PW123499', 26000.00, 31999.99, '2023-05-20', 'maintenance'),
('V1055', 'Hyundai', 'Tucson', 2022, 'KM8J3CAL6NU123500', 24000.00, 28999.99, '2023-05-22', 'in_stock'),
('V1056', 'Hyundai', 'Santa Fe', 2023, '5NMS3DAJ9PH123501', 29000.00, 34999.99, '2023-05-25', 'in_stock'),
('V1057', 'Kia', 'Sportage', 2022, 'KNDP63DL3N7123502', 25000.00, 29999.99, '2023-05-27', 'sold'),
('V1058', 'Kia', 'Telluride', 2023, '5XYP64LC9PG123503', 36000.00, 42999.99, '2023-05-30', 'in_stock'),
('V1059', 'Mazda', 'CX-5', 2022, 'JM3KFBDM0N0123504', 27000.00, 32999.99, '2023-06-01', 'in_stock'),
('V1060', 'Mazda', 'CX-9', 2023, 'JM3TCBDY3P0123505', 34000.00, 39999.99, '2023-06-03', 'in_stock');

-- INSERT statements for cars table - 40 cars (excludes SUVs/Trucks)
INSERT INTO cars (vehicle_id, car_id, make, model, year, vin, purchase_price, price, date_acquired, status, body_type, fuel_type, transmission, mileage, engine_size)
VALUES
-- Toyota cars
('V1001', 'C1001', 'Toyota', 'Corolla', 2022, 'JT2BF22K1X0123456', 18500.00, 21999.99, '2023-01-15', 'in_stock', 'sedan', 'gasoline', 'cvt', 5200, 1.8),
('V1002', 'C1002', 'Toyota', 'Camry', 2022, '4T1BF1FK5NU123457', 24500.00, 28999.99, '2023-01-16', 'in_stock', 'sedan', 'gasoline', 'automatic', 3800, 2.5),
('V1008', 'C1008', 'Toyota', 'Avalon', 2021, '4T1BZ1FB3MU123463', 32000.00, 36999.99, '2023-01-30', 'in_stock', 'sedan', 'gasoline', 'automatic', 7200, 3.5),
('V1044', 'C1044', 'Toyota', 'Prius', 2023, 'JTDKAMFP4P3123491', 28000.00, 32999.99, '2023-04-25', 'in_stock', 'hatchback', 'hybrid', 'cvt', 1200, 1.8),

-- Honda cars
('V1009', 'C1009', 'Honda', 'Civic', 2022, '2HGFE2F53NH123464', 21000.00, 24999.99, '2023-02-01', 'in_stock', 'sedan', 'gasoline', 'cvt', 4500, 1.5),
('V1010', 'C1010', 'Honda', 'Accord', 2022, '1HGCV2F34NA123465', 25000.00, 29999.99, '2023-02-03', 'sold', 'sedan', 'gasoline', 'automatic', 3200, 1.5),
('V1014', 'C1014', 'Honda', 'HR-V', 2023, '3CZRU6H73PM123469', 23000.00, 27999.99, '2023-02-12', 'in_stock', 'crossover', 'gasoline', 'cvt', 2100, 1.8),

-- Ford cars
('V1019', 'C1019', 'Ford', 'Mustang', 2022, '1FA6P8TH2N5123472', 39000.00, 45999.99, '2023-02-25', 'in_stock', 'coupe', 'gasoline', 'automatic', 2800, 5.0),

-- Chevrolet cars
('V1027', 'C1027', 'Chevrolet', 'Malibu', 2022, '1G1ZD5ST9NF123479', 22000.00, 26999.99, '2023-03-15', 'sold', 'sedan', 'gasoline', 'automatic', 5500, 1.5),

-- BMW cars
('V1029', 'C1029', 'BMW', '3 Series', 2022, 'WBA3N5C51EK123456', 41000.00, 47500.00, '2023-03-20', 'in_stock', 'sedan', 'gasoline', 'automatic', 3200, 2.0),
('V1030', 'C1030', 'BMW', '5 Series', 2023, 'WBA13AL01PCF12348', 52000.00, 59999.99, '2023-03-22', 'in_stock', 'sedan', 'gasoline', 'automatic', 1800, 3.0),

-- Mercedes cars
('V1033', 'C1033', 'Mercedes-Benz', 'C-Class', 2022, '55SWF8EB1NU123483', 43000.00, 49999.99, '2023-03-30', 'in_stock', 'sedan', 'gasoline', 'automatic', 2900, 2.0),
('V1034', 'C1034', 'Mercedes-Benz', 'E-Class', 2021, 'WDDZF4JB1KA123456', 52000.00, 58999.99, '2023-04-01', 'sold', 'sedan', 'gasoline', 'automatic', 7500, 3.0),

-- Audi cars
('V1037', 'C1037', 'Audi', 'A4', 2023, 'WAUENAF46JN123456', 43000.00, 49999.99, '2023-04-08', 'in_stock', 'sedan', 'gasoline', 'automatic', 2800, 2.0),
('V1039', 'C1039', 'Audi', 'A6', 2023, 'WAUE8AF27PN123487', 54000.00, 61999.99, '2023-04-12', 'sold', 'sedan', 'gasoline', 'automatic', 1900, 3.0),

-- Tesla cars
('V1041', 'C1041', 'Tesla', 'Model 3', 2023, '5YJ3E1EA1PF123456', 42000.00, 48999.99, '2023-04-17', 'in_stock', 'sedan', 'electric', 'automatic', 1200, 0.0),
('V1042', 'C1042', 'Tesla', 'Model Y', 2022, '5YJYGDEE9NF123489', 48000.00, 54999.99, '2023-04-20', 'sold', 'crossover', 'electric', 'automatic', 3600, 0.0),
('V1043', 'C1043', 'Tesla', 'Model S', 2022, '5YJSA1E44NF123490', 75000.00, 84999.99, '2023-04-22', 'in_stock', 'sedan', 'electric', 'automatic', 2100, 0.0),

-- Hyundai/Kia cars
('V1045', 'C1045', 'Hyundai', 'IONIQ 5', 2022, 'KM8KR4AE4NU123492', 39000.00, 45999.99, '2023-04-27', 'sold', 'crossover', 'electric', 'automatic', 2800, 0.0),
('V1046', 'C1046', 'Kia', 'EV6', 2023, 'KNDCR3LD4P5123493', 41000.00, 47999.99, '2023-04-30', 'in_stock', 'crossover', 'electric', 'automatic', 1500, 0.0),

-- Nissan cars
('V1053', 'C1053', 'Nissan', 'Altima', 2022, '1N4BL4EV3NC123498', 23000.00, 27999.99, '2023-05-17', 'in_stock', 'sedan', 'gasoline', 'cvt', 4200, 2.5);

-- INSERT statements for sedans table - 15 sedans
INSERT INTO sedans (vehicle_id, car_id, sedan_id, make, model, year, vin, purchase_price, price, date_acquired, status, body_type, fuel_type, transmission, mileage, engine_size, luxury_level)
VALUES
-- Toyota sedans
('V1001', 'C1001', 'S1001', 'Toyota', 'Corolla', 2022, 'JT2BF22K1X0123456', 18500.00, 21999.99, '2023-01-15', 'in_stock', 'sedan', 'gasoline', 'cvt', 5200, 1.8, 'standard'),
('V1002', 'C1002', 'S1002', 'Toyota', 'Camry', 2022, '4T1BF1FK5NU123457', 24500.00, 28999.99, '2023-01-16', 'in_stock', 'sedan', 'gasoline', 'automatic', 3800, 2.5, 'standard'),
('V1008', 'C1008', 'S1008', 'Toyota', 'Avalon', 2021, '4T1BZ1FB3MU123463', 32000.00, 36999.99, '2023-01-30', 'in_stock', 'sedan', 'gasoline', 'automatic', 7200, 3.5, 'luxury'),

-- Honda sedans
('V1009', 'C1009', 'S1009', 'Honda', 'Civic', 2022, '2HGFE2F53NH123464', 21000.00, 24999.99, '2023-02-01', 'in_stock', 'sedan', 'gasoline', 'cvt', 4500, 1.5, 'standard'),
('V1010', 'C1010', 'S1010', 'Honda', 'Accord', 2022, '1HGCV2F34NA123465', 25000.00, 29999.99, '2023-02-03', 'sold', 'sedan', 'gasoline', 'automatic', 3200, 1.5, 'standard'),

-- Chevrolet sedans
('V1027', 'C1027', 'S1027', 'Chevrolet', 'Malibu', 2022, '1G1ZD5ST9NF123479', 22000.00, 26999.99, '2023-03-15', 'sold', 'sedan', 'gasoline', 'automatic', 5500, 1.5, 'standard'),

-- BMW sedans (luxury)
('V1029', 'C1029', 'S1029', 'BMW', '3 Series', 2022, 'WBA3N5C51EK123456', 41000.00, 47500.00, '2023-03-20', 'in_stock', 'sedan', 'gasoline', 'automatic', 3200, 2.0, 'luxury'),
('V1030', 'C1030', 'S1030', 'BMW', '5 Series', 2023, 'WBA13AL01PCF12348', 52000.00, 59999.99, '2023-03-22', 'in_stock', 'sedan', 'gasoline', 'automatic', 1800, 3.0, 'premium'),

-- Mercedes sedans (luxury)
('V1033', 'C1033', 'S1033', 'Mercedes-Benz', 'C-Class', 2022, '55SWF8EB1NU123483', 43000.00, 49999.99, '2023-03-30', 'in_stock', 'sedan', 'gasoline', 'automatic', 2900, 2.0, 'luxury'),
('V1034', 'C1034', 'S1034', 'Mercedes-Benz', 'E-Class', 2021, 'WDDZF4JB1KA123456', 52000.00, 58999.99, '2023-04-01', 'sold', 'sedan', 'gasoline', 'automatic', 7500, 3.0, 'premium'),

-- Audi sedans (luxury)
('V1037', 'C1037', 'S1037', 'Audi', 'A4', 2023, 'WAUENAF46JN123456', 43000.00, 49999.99, '2023-04-08', 'in_stock', 'sedan', 'gasoline', 'automatic', 2800, 2.0, 'luxury'),
('V1039', 'C1039', 'S1039', 'Audi', 'A6', 2023, 'WAUE8AF27PN123487', 54000.00, 61999.99, '2023-04-12', 'sold', 'sedan', 'gasoline', 'automatic', 1900, 3.0, 'premium'),

-- Tesla sedans (electric luxury)
('V1041', 'C1041', 'S1041', 'Tesla', 'Model 3', 2023, '5YJ3E1EA1PF123456', 42000.00, 48999.99, '2023-04-17', 'in_stock', 'sedan', 'electric', 'automatic', 1200, 0.0, 'premium'),
('V1043', 'C1043', 'S1043', 'Tesla', 'Model S', 2022, '5YJSA1E44NF123490', 75000.00, 84999.99, '2023-04-22', 'in_stock', 'sedan', 'electric', 'automatic', 2100, 0.0, 'ultra'),

-- Nissan sedan
('V1053', 'C1053', 'S1053', 'Nissan', 'Altima', 2022, '1N4BL4EV3NC123498', 23000.00, 27999.99, '2023-05-17', 'in_stock', 'sedan', 'gasoline', 'cvt', 4200, 2.5, 'standard');

-- INSERT statements for suvs table - 15 suvs
INSERT INTO suvs (vehicle_id, car_id, suv_id, make, model, year, vin, purchase_price, price, date_acquired, status, body_type, fuel_type, transmission, mileage, engine_size, seating_capacity, cargo_capacity, ground_clearance, awd_4wd)
VALUES
    ('V1003', 'C1003', 'SUV1001', 'Toyota', 'RAV4', 2023, '2T3F1RFV8MW123458', 28000.00, 32999.99, '2023-01-18', 'in_stock', 'suv', 'gasoline', 'automatic', 2800, 2.5, 5, 69.8, 8.4, TRUE),
    ('V1004', 'C1004', 'SUV1002', 'Toyota', 'Highlander', 2022, '5TDKZRFH1NS123459', 35000.00, 39999.99, '2023-01-20', 'sold', 'suv', 'gasoline', 'automatic', 8500, 3.5, 8, 84.3, 8.0, TRUE),
    ('V1011', 'C1011', 'SUV1003', 'Honda', 'CR-V', 2023, '7FARW2H58PE123466', 28500.00, 33999.99, '2023-02-05', 'in_stock', 'suv', 'gasoline', 'cvt', 3200, 1.5, 5, 75.8, 8.2, TRUE),
    ('V1012', 'C1012', 'SUV1004', 'Honda', 'Pilot', 2022, '5FNYF8H91NB123467', 36000.00, 41999.99, '2023-02-08', 'in_stock', 'suv', 'gasoline', 'automatic', 5800, 3.5, 8, 109.0, 7.3, TRUE),
    ('V1017', 'C1017', 'SUV1005', 'Ford', 'Escape', 2022, '1FMCU9G69NU123471', 25000.00, 29999.99, '2023-02-20', 'sold', 'suv', 'gasoline', 'automatic', 6700, 1.5, 5, 65.4, 7.8, FALSE),
    ('V1018', 'C1018', 'SUV1006', 'Ford', 'Explorer', 2023, '1FM5K8JT1PGA12347', 36000.00, 42999.99, '2023-02-22', 'in_stock', 'suv', 'gasoline', 'automatic', 3100, 2.3, 7, 87.8, 8.2, TRUE),
-- Continuation of SUVs data
    ('V1020', 'C1020', 'SUV1007', 'Ford', 'Edge', 2022, '2FMPK4J98NB123473', 32000.00, 37999.99, '2023-02-27', 'maintenance', 'suv', 'gasoline', 'automatic', 7200, 2.0, 5, 73.4, 8.0, FALSE),
    ('V1021', 'C1021', 'SUV1008', 'Ford', 'Bronco', 2023, '1FMEE5DP7PL123474', 42000.00, 48999.99, '2023-03-01', 'in_stock', 'suv', 'gasoline', 'automatic', 2900, 2.7, 5, 77.6, 11.6, TRUE),
    ('V1024', 'C1024', 'SUV1009', 'Chevrolet', 'Equinox', 2022, '2GNFLFEK8D6123456', 24500.00, 28999.99, '2023-03-07', 'sold', 'suv', 'gasoline', 'automatic', 8900, 1.5, 5, 63.9, 7.6, FALSE),
    ('V1025', 'C1025', 'SUV1010', 'Chevrolet', 'Tahoe', 2022, '1GNSKCKD3NR123477', 48000.00, 55999.99, '2023-03-10', 'in_stock', 'suv', 'gasoline', 'automatic', 4300, 5.3, 8, 122.9, 8.0, TRUE),
    ('V1026', 'C1026', 'SUV1011', 'Chevrolet', 'Traverse', 2023, '1GNEVKKW1PJ123478', 34000.00, 39999.99, '2023-03-12', 'in_stock', 'suv', 'gasoline', 'automatic', 3600, 3.6, 8, 98.2, 7.5, TRUE),
    ('V1031', 'C1031', 'SUV1012', 'BMW', 'X3', 2022, '5UXTY5C06N9123481', 44000.00, 50999.99, '2023-03-25', 'sold', 'suv', 'gasoline', 'automatic', 5600, 2.0, 5, 62.7, 8.0, TRUE),
    ('V1032', 'C1032', 'SUV1013', 'BMW', 'X5', 2023, '5UXCR6C06P9123482', 58000.00, 65999.99, '2023-03-27', 'in_stock', 'suv', 'gasoline', 'automatic', 2800, 3.0, 5, 72.3, 8.7, TRUE),
    ('V1035', 'C1035', 'SUV1014', 'Mercedes-Benz', 'GLC', 2023, 'W1N0G8EB9PF123484', 48000.00, 55999.99, '2023-04-03', 'in_stock', 'suv', 'gasoline', 'automatic', 2100, 2.0, 5, 56.5, 7.5, TRUE),
    ('V1036', 'C1036', 'SUV1015', 'Mercedes-Benz', 'GLE', 2022, 'W1N0G8DB4NM123485', 58000.00, 66999.99, '2023-04-05', 'maintenance', 'suv', 'gasoline', 'automatic', 7800, 3.0, 5, 74.9, 8.0, TRUE);

-- INSERT statements for trucks table - 10 trucks
INSERT INTO trucks (vehicle_id, car_id, truck_id, make, model, year, vin, purchase_price, price, date_acquired, status, body_type, fuel_type, transmission, mileage, engine_size, bed_length, towing_capacity, payload_capacity, cab_type)
VALUES
    ('V1005', 'C1005', 'T1001', 'Toyota', 'Tacoma', 2023, '3TMCZ5AN9PM123460', 32000.00, 37999.99, '2023-01-22', 'in_stock', 'truck', 'gasoline', 'automatic', 2800, 3.5, 5.0, 6800, 1440, 'crew'),
    ('V1006', 'C1006', 'T1002', 'Toyota', 'Tundra', 2022, '5TFHY5F10NX123461', 42000.00, 48999.99, '2023-01-25', 'sold', 'truck', 'gasoline', 'automatic', 6500, 5.7, 6.5, 10200, 1730, 'crew'),
    ('V1015', 'C1015', 'T1003', 'Honda', 'Ridgeline', 2022, '5FPYK3F79NB123470', 35000.00, 40999.99, '2023-02-15', 'in_stock', 'truck', 'gasoline', 'automatic', 3900, 3.5, 5.3, 5000, 1583, 'crew'),
    ('V1016', 'C1016', 'T1004', 'Ford', 'F-150', 2023, '1FTFW1ET3DFA12345', 38000.00, 44999.99, '2023-02-18', 'in_stock', 'truck', 'gasoline', 'automatic', 2700, 3.5, 6.5, 13200, 2238, 'crew'),
    ('V1022', 'C1022', 'T1005', 'Ford', 'Ranger', 2022, '1FTER4FH2NL123475', 29000.00, 34999.99, '2023-03-03', 'in_stock', 'truck', 'gasoline', 'automatic', 4500, 2.3, 5.0, 7500, 1860, 'extended'),
    ('V1023', 'C1023', 'T1006', 'Chevrolet', 'Silverado', 2023, '3GCUYEED9PG123476', 40000.00, 46999.99, '2023-03-05', 'in_stock', 'truck', 'gasoline', 'automatic', 3100, 5.3, 6.5, 13300, 2280, 'crew'),
    ('V1038', 'C1038', 'T1007', 'GMC', 'Sierra', 2022, 'WAUG8AFY7N2123486', 46000.00, 53999.99, '2023-04-10', 'in_stock', 'truck', 'diesel', 'automatic', 5200, 3.0, 6.5, 12100, 2240, 'crew'),
    ('V1048', 'C1048', 'T1008', 'Jeep', 'Gladiator', 2023, '1C4HJXEG5PS123494', 41000.00, 47999.99, '2023-05-05', 'sold', 'truck', 'gasoline', 'automatic', 4800, 3.6, 5.0, 7650, 1700, 'crew'),
    ('V1049', 'C1049', 'T1009', 'Ram', '1500', 2022, '1C6RR7LG8LS123456', 39000.00, 45500.00, '2023-05-07', 'in_stock', 'truck', 'gasoline', 'automatic', 4200, 5.7, 6.4, 12750, 2300, 'crew'),
    ('V1050', 'C1050', 'T1010', 'Ram', '2500', 2023, '3C6UR5FL4PG123495', 48000.00, 55999.99, '2023-05-10', 'in_stock', 'truck', 'diesel', 'automatic', 3500, 6.7, 8.0, 19680, 3990, 'crew');

-- INSERT statements for parts table - with higher quantities
INSERT INTO parts (part_id, name, description, category, part_number, price, quantity_in_stock, reorder_threshold, reorder_quantity, supplier_id)
VALUES
    ('P1001', 'Air Filter', 'Standard air filter for sedans', 'Filters', 'AF-1234', 15.99, 125, 30, 75, 'S1001'),
    ('P1002', 'Brake Pad Set', 'Front brake pads for most models', 'Brakes', 'BP-5678', 79.99, 92, 25, 50, 'S1002'),
    ('P1003', 'Oil Filter', 'Standard oil filter for gasoline engines', 'Filters', 'OF-9012', 9.99, 180, 50, 100, 'S1001'),
    ('P1004', 'Spark Plug Set', 'Set of 4 spark plugs', 'Ignition', 'SP-3456', 24.99, 87, 30, 60, 'S1003'),
    ('P1005', 'Wiper Blade Set', 'Front wiper blades - universal', 'Exterior', 'WB-7890', 29.99, 108, 40, 80, 'S1004'),
    ('P1006', 'Battery', '12V battery for most vehicles', 'Electrical', 'BAT-1234', 119.99, 45, 15, 30, 'S1005'),
    ('P1007', 'Headlight Bulb', 'Standard halogen headlight bulb', 'Lighting', 'HB-5678', 14.99, 150, 40, 100, 'S1004'),
    ('P1008', 'Cabin Air Filter', 'Standard cabin air filter', 'Filters', 'CAF-9012', 19.99, 110, 35, 70, 'S1001'),
    ('P1009', 'Engine Oil - 5W-30', '5 quart synthetic oil', 'Fluids', 'OIL-5W30', 34.99, 200, 60, 120, 'S1006'),
    ('P1010', 'Transmission Fluid', 'Automatic transmission fluid - 1 quart', 'Fluids', 'TF-1234', 12.99, 135, 40, 80, 'S1006'),
    ('P1011', 'Antifreeze/Coolant', 'All-season antifreeze - 1 gallon', 'Fluids', 'AF-5678', 18.99, 95, 30, 60, 'S1006'),
    ('P1012', 'Serpentine Belt', 'Standard serpentine belt', 'Engine', 'SB-9012', 29.99, 65, 20, 40, 'S1007'),
    ('P1013', 'Alternator', 'Replacement alternator', 'Electrical', 'ALT-3456', 189.99, 32, 10, 20, 'S1005'),
    ('P1014', 'Starter Motor', 'Replacement starter motor', 'Electrical', 'SM-7890', 149.99, 28, 8, 16, 'S1005'),
    ('P1015', 'Oxygen Sensor', 'Upstream O2 sensor', 'Emissions', 'OS-1234', 49.99, 42, 15, 30, 'S1008'),
    ('P1016', 'Radiator', 'Aluminum radiator for sedans', 'Cooling', 'RAD-5678', 159.99, 25, 8, 16, 'S1009'),
    ('P1017', 'Water Pump', 'Engine water pump', 'Cooling', 'WP-9012', 89.99, 35, 12, 24, 'S1009'),
    ('P1018', 'Thermostat', 'Engine thermostat', 'Cooling', 'TS-3456', 19.99, 55, 20, 40, 'S1009'),
    ('P1019', 'Fuel Pump', 'In-tank fuel pump assembly', 'Fuel', 'FP-7890', 129.99, 30, 10, 20, 'S1010'),
    ('P1020', 'Fuel Filter', 'Inline fuel filter', 'Fuel', 'FF-1234', 24.99, 75, 25, 50, 'S1010'),
    ('P1021', 'Shock Absorber', 'Front shock/strut', 'Suspension', 'SA-5678', 79.99, 48, 16, 32, 'S1011'),
    ('P1022', 'Coil Spring', 'Front coil spring', 'Suspension', 'CS-9012', 69.99, 40, 15, 30, 'S1011'),
    ('P1023', 'Control Arm', 'Front lower control arm', 'Suspension', 'CA-3456', 89.99, 32, 12, 24, 'S1011'),
    ('P1024', 'Tie Rod End', 'Outer tie rod end', 'Steering', 'TR-7890', 39.99, 45, 15, 30, 'S1012'),
    ('P1025', 'Power Steering Pump', 'Power steering pump', 'Steering', 'PSP-1234', 119.99, 25, 8, 16, 'S1012'),
    ('P1026', 'Steering Rack', 'Complete steering rack', 'Steering', 'SR-5678', 299.99, 18, 6, 12, 'S1012'),
    ('P1027', 'Air Conditioning Compressor', 'A/C compressor', 'HVAC', 'ACC-9012', 249.99, 22, 7, 14, 'S1013'),
    ('P1028', 'Blower Motor', 'HVAC blower motor', 'HVAC', 'BM-3456', 89.99, 30, 10, 20, 'S1013'),
    ('P1029', 'Radiator Fan', 'Electric cooling fan assembly', 'Cooling', 'RF-7890', 129.99, 25, 8, 16, 'S1009'),
    ('P1030', 'Ignition Coil', 'Individual ignition coil', 'Ignition', 'IC-1234', 59.99, 60, 20, 40, 'S1003');

-- Updated INSERT statements for vehicle_parts relationship with varying quantities
INSERT INTO vehicle_parts (vehicle_id, part_id, quantity, installed_date)
VALUES
-- Regular maintenance items typically installed in 1s
('V1001', 'P1001', 1, '2023-01-20'),  -- Air filter
('V1001', 'P1003', 1, '2023-01-20'),  -- Oil filter
('V1001', 'P1008', 1, '2023-01-20'),  -- Cabin air filter

-- Some vehicles need multiple spark plugs (4, 6, or 8 depending on engine)
('V1002', 'P1004', 4, '2023-01-19'),  -- 4 spark plugs for 4-cylinder
('V1019', 'P1004', 8, '2023-02-28'),  -- 8 spark plugs for V8 Mustang

-- Wipers typically come in pairs
('V1003', 'P1005', 2, '2023-01-22'),  -- Pair of wiper blades
('V1020', 'P1005', 2, '2023-03-02'),  -- Pair of wiper blades

-- Brake pads are typically installed in sets of 2 or 4
('V1004', 'P1002', 4, '2023-01-25'),  -- Front and rear brake pads
('V1012', 'P1002', 2, '2023-02-10'),  -- Front brake pads only

-- Various quantities of oil for different vehicles
('V1005', 'P1009', 5, '2023-01-26'),  -- 5 quarts of oil for smaller engine
('V1006', 'P1009', 7, '2023-01-28'),  -- 7 quarts of oil for larger engine
('V1023', 'P1009', 8, '2023-03-10'),  -- 8 quarts of oil for truck

-- Transmission fluid can vary based on transmission type
('V1007', 'P1010', 6, '2023-01-30'),  -- 6 quarts of transmission fluid
('V1016', 'P1010', 12, '2023-02-20'), -- 12 quarts for larger truck transmission

-- Coolant quantities
('V1008', 'P1011', 2, '2023-02-02'),  -- 2 gallons of coolant
('V1025', 'P1011', 3, '2023-03-12'),  -- 3 gallons for larger vehicle

-- Multiple oxygen sensors on some vehicles
('V1009', 'P1015', 2, '2023-02-04'),  -- 2 oxygen sensors
('V1031', 'P1015', 4, '2023-03-27'),  -- 4 oxygen sensors for luxury car

-- Single unit installations
('V1010', 'P1006', 1, '2023-02-05'),  -- Battery
('V1011', 'P1013', 1, '2023-02-07'),  -- Alternator
('V1014', 'P1014', 1, '2023-02-15'),  -- Starter motor
('V1015', 'P1016', 1, '2023-02-18'),  -- Radiator
('V1017', 'P1017', 1, '2023-02-22'),  -- Water pump

-- Bulk fluids for service center
('V1018', 'P1009', 15, '2023-02-25'), -- 15 quarts bulk engine oil
('V1018', 'P1010', 10, '2023-02-25'), -- 10 quarts bulk transmission fluid
('V1018', 'P1011', 5, '2023-02-25'),  -- 5 gallons bulk coolant

-- Multiple sets of same part for fleet vehicles
('V1022', 'P1001', 3, '2023-03-08'),  -- 3 air filters (fleet maintenance)
('V1022', 'P1003', 3, '2023-03-08'),  -- 3 oil filters (fleet maintenance)
('V1022', 'P1008', 3, '2023-03-08'),  -- 3 cabin filters (fleet maintenance)

-- Suspension components often installed in pairs
('V1026', 'P1021', 2, '2023-03-14'), -- 2 front shock absorbers
('V1026', 'P1022', 2, '2023-03-14'), -- 2 front coil springs
('V1036', 'P1021', 4, '2023-04-07'), -- 4 shock absorbers (all corners)

-- Steering components
('V1027', 'P1024', 2, '2023-03-16'), -- 2 tie rod ends
('V1038', 'P1025', 1, '2023-04-12'), -- Power steering pump

-- Ignition components for service
('V1028', 'P1030', 6, '2023-03-19'), -- 6 ignition coils for 6-cylinder
('V1043', 'P1030', 8, '2023-04-24'), -- 8 ignition coils for luxury vehicle

-- A/C service
('V1029', 'P1027', 1, '2023-03-22'), -- A/C compressor
('V1033', 'P1028', 1, '2023-04-01'), -- Blower motor

-- Cooling system components
('V1030', 'P1029', 1, '2023-03-25'), -- Radiator fan
('V1037', 'P1016', 1, '2023-04-10'), -- Radiator
('V1037', 'P1017', 1, '2023-04-10'), -- Water pump
('V1037', 'P1018', 1, '2023-04-10'), -- Thermostat

-- Fuel system
('V1039', 'P1019', 1, '2023-04-14'), -- Fuel pump
('V1039', 'P1020', 1, '2023-04-14'), -- Fuel filter

-- Control arms typically replaced in pairs
('V1040', 'P1023', 2, '2023-04-17'), -- 2 control arms

-- Multiple units for service department stock
('V1044', 'P1007', 12, '2023-04-28'), -- 12 headlight bulbs for service stock
('V1044', 'P1018', 8, '2023-04-28'),  -- 8 thermostats for service stock
('V1044', 'P1003', 24, '2023-04-28'), -- 24 oil filters for service stock

-- Heavy-duty truck service
('V1050', 'P1009', 12, '2023-05-12'), -- 12 quarts oil for diesel truck
('V1050', 'P1003', 2, '2023-05-12'),  -- 2 oil filters for diesel (primary and secondary)
('V1050', 'P1020', 2, '2023-05-12'),  -- 2 fuel filters for diesel (primary and secondary)

-- Multiple components for major repairs
('V1054', 'P1021', 4, '2023-05-22'), -- 4 shock absorbers
('V1054', 'P1022', 4, '2023-05-22'), -- 4 coil springs
('V1054', 'P1023', 4, '2023-05-22'), -- 4 control arms
('V1054', 'P1024', 4, '2023-05-22'), -- 4 tie rod ends

-- Large order for service department
('V1058', 'P1001', 10, '2023-06-01'), -- 10 air filters
('V1058', 'P1003', 20, '2023-06-01'), -- 20 oil filters
('V1058', 'P1004', 30, '2023-06-01'), -- 30 spark plugs
('V1058', 'P1005', 15, '2023-06-01'), -- 15 wiper blade sets
('V1058', 'P1007', 25, '2023-06-01'), -- 25 headlight bulbs
('V1058', 'P1008', 10, '2023-06-01'); -- 10 cabin air filters

-- INSERT statements for customers - 50 customers
INSERT INTO customers (customer_id, username, first_name, last_name, email, phone, password_hash, is_active)
VALUES
    ('C1001', 'jsmith', 'John', 'Smith', 'john.smith@example.com', '+1 555-123-4567', '$2a$12$1234567890abcdefghijk', TRUE),
    ('C1002', 'mgarcia', 'Maria', 'Garcia', 'maria.garcia@example.com', '+1 555-234-5678', '$2a$12$abcdefghijk1234567890', TRUE),
    ('C1003', 'rjohnson', 'Robert', 'Johnson', 'robert.johnson@example.com', '+1 555-345-6789', '$2a$12$ghijk1234567890abcdef', TRUE),
    ('C1004', 'lwong', 'Linda', 'Wong', 'linda.wong@example.com', '+1 555-456-7890', '$2a$12$567890abcdefghijk12345', TRUE),
    ('C1005', 'mrodriguez', 'Miguel', 'Rodriguez', 'miguel.rodriguez@example.com', '+1 555-567-8901', '$2a$12$890abcdefghijk123456789', TRUE),
    ('C1006', 'spatil', 'Samir', 'Patil', 'samir.patil@example.com', '+1 555-678-9012', '$2a$12$defghijk1234567890abcd', TRUE),
    ('C1007', 'joliver', 'James', 'Oliver', 'james.oliver@example.com', '+1 555-789-0123', '$2a$12$34567890abcdefghijk123', TRUE),
    ('C1008', 'klee', 'Kelly', 'Lee', 'kelly.lee@example.com', '+1 555-890-1234', '$2a$12$7890abcdefghijk12345678', TRUE),
    ('C1009', 'jwilliams', 'Jennifer', 'Williams', 'jennifer.williams@example.com', '+1 555-901-2345', '$2a$12$12345678abcdefghijk890', TRUE),
    ('C1010', 'mbrown', 'Michael', 'Brown', 'michael.brown@example.com', '+1 555-012-3456', '$2a$12$56789abcdefghijk1234567', TRUE),
    ('C1011', 'tkim', 'Thomas', 'Kim', 'thomas.kim@example.com', '+1 555-123-5678', '$2a$12$89abcdefghijk123456789a', TRUE),
    ('C1012', 'sjones', 'Sarah', 'Jones', 'sarah.jones@example.com', '+1 555-234-6789', '$2a$12$bcdefghijk1234567890abc', TRUE),
    ('C1013', 'dthomas', 'David', 'Thomas', 'david.thomas@example.com', '+1 555-345-7890', '$2a$12$efghijk1234567890abcdef', TRUE),
    ('C1014', 'amiller', 'Amy', 'Miller', 'amy.miller@example.com', '+1 555-456-8901', '$2a$12$hijk1234567890abcdefghi', TRUE),
    ('C1015', 'jdavis', 'James', 'Davis', 'james.davis@example.com', '+1 555-567-9012', '$2a$12$jk1234567890abcdefghijk', TRUE),
    ('C1016', 'mwilson', 'Michelle', 'Wilson', 'michelle.wilson@example.com', '+1 555-678-0123', '$2a$12$234567890abcdefghijk123', TRUE),
    ('C1017', 'rmoore', 'Richard', 'Moore', 'richard.moore@example.com', '+1 555-789-1234', '$2a$12$567890abcdefghijk567890', TRUE),
    ('C1018', 'ltaylor', 'Lisa', 'Taylor', 'lisa.taylor@example.com', '+1 555-890-2345', '$2a$12$890abcdefghijk1234567890', TRUE),
    ('C1019', 'janderson', 'Joseph', 'Anderson', 'joseph.anderson@example.com', '+1 555-901-3456', '$2a$12$abcdefghijk123456789abcd', TRUE),
    ('C1020', 'nthomas', 'Nicole', 'Thomas', 'nicole.thomas@example.com', '+1 555-012-4567', '$2a$12$efghijk1234567890efghijk', TRUE),
    ('C1021', 'crobinson', 'Charles', 'Robinson', 'charles.robinson@example.com', '+1 555-123-6789', '$2a$12$hijk1234567890abcdhijk12', TRUE),
    ('C1022', 'jlewis', 'Jessica', 'Lewis', 'jessica.lewis@example.com', '+1 555-234-7890', '$2a$12$jk1234567890abcdefgjk1234', TRUE),
    ('C1023', 'mwalker', 'Matthew', 'Walker', 'matthew.walker@example.com', '+1 555-345-8901', '$2a$12$234567890abcdefghi2345678', TRUE),
    ('C1024', 'aperez', 'Amanda', 'Perez', 'amanda.perez@example.com', '+1 555-456-9012', '$2a$12$567890abcdefghijk5678901', TRUE),
    ('C1025', 'bhall', 'Brian', 'Hall', 'brian.hall@example.com', '+1 555-567-0123', '$2a$12$890abcdefghijk12348901234', TRUE),
    ('C1026', 'sgriffin', 'Stephanie', 'Griffin', 'stephanie.griffin@example.com', '+1 555-678-1234', '$2a$12$abcdefghijk12345678abcdef', TRUE),
    ('C1027', 'kbaker', 'Kevin', 'Baker', 'kevin.baker@example.com', '+1 555-789-2345', '$2a$12$efghijk1234567890efghijkl', TRUE),
    ('C1028', 'eadams', 'Emily', 'Adams', 'emily.adams@example.com', '+1 555-890-3456', '$2a$12$hijk1234567890abcdhijklmn', TRUE),
    ('C1029', 'cnelson', 'Christopher', 'Nelson', 'christopher.nelson@example.com', '+1 555-901-4567', '$2a$12$jk1234567890abcdefgjklmno', TRUE),
    ('C1030', 'ahill', 'Ashley', 'Hill', 'ashley.hill@example.com', '+1 555-012-5678', '$2a$12$234567890abcdefghi23456789', TRUE),
    ('C1031', 'jmurphy', 'Joshua', 'Murphy', 'joshua.murphy@example.com', '+1 555-123-7890', '$2a$12$567890abcdefghijk56789012', TRUE),
    ('C1032', 'arivera', 'Amanda', 'Rivera', 'amanda.rivera@example.com', '+1 555-234-8901', '$2a$12$890abcdefghijk123489012345', TRUE),
    ('C1033', 'jcook', 'Justin', 'Cook', 'justin.cook@example.com', '+1 555-345-9012', '$2a$12$abcdefghijk12345678abcdefg', TRUE),
    ('C1034', 'mross', 'Melissa', 'Ross', 'melissa.ross@example.com', '+1 555-456-0123', '$2a$12$efghijk1234567890efghijklm', TRUE),
    ('C1035', 'drogers', 'Daniel', 'Rogers', 'daniel.rogers@example.com', '+1 555-567-1234', '$2a$12$hijk1234567890abcdhijklmno', TRUE),
    ('C1036', 'sphillips', 'Stephanie', 'Phillips', 'stephanie.phillips@example.com', '+1 555-678-2345', '$2a$12$jk1234567890abcdefgjklmnop', TRUE),
    ('C1037', 'pwatson', 'Patrick', 'Watson', 'patrick.watson@example.com', '+1 555-789-3456', '$2a$12$234567890abcdefghi234567890', TRUE),
    ('C1038', 'abrooks', 'Amanda', 'Brooks', 'amanda.brooks@example.com', '+1 555-890-4567', '$2a$12$567890abcdefghijk567890123', TRUE),
    ('C1039', 'rjones', 'Ryan', 'Jones', 'ryan.jones@example.com', '+1 555-901-5678', '$2a$12$890abcdefghijk1234890123456', TRUE),
    ('C1040', 'lbennett', 'Laura', 'Bennett', 'laura.bennett@example.com', '+1 555-012-6789', '$2a$12$abcdefghijk12345678abcdefgh', TRUE),
    ('C1041', 'gwood', 'Gary', 'Wood', 'gary.wood@example.com', '+1 555-123-8901', '$2a$12$efghijk1234567890efghijklmn', TRUE),
    ('C1042', 'sbarnes', 'Susan', 'Barnes', 'susan.barnes@example.com', '+1 555-234-9012', '$2a$12$hijk1234567890abcdhijklmnop', TRUE),
    ('C1043', 'tross', 'Tyler', 'Ross', 'tyler.ross@example.com', '+1 555-345-0123', '$2a$12$jk1234567890abcdefgjklmnopq', TRUE),
    ('C1044', 'ahoward', 'Amanda', 'Howard', 'amanda.howard@example.com', '+1 555-456-1234', '$2a$12$234567890abcdefghi2345678901', TRUE),
    ('C1045', 'dward', 'Dennis', 'Ward', 'dennis.ward@example.com', '+1 555-567-2345', '$2a$12$567890abcdefghijk5678901234', TRUE),
    ('C1046', 'sturner', 'Sarah', 'Turner', 'sarah.turner@example.com', '+1 555-678-3456', '$2a$12$890abcdefghijk12348901234567', TRUE),
    ('C1047', 'jparker', 'Jonathan', 'Parker', 'jonathan.parker@example.com', '+1 555-789-4567', '$2a$12$abcdefghijk12345678abcdefghi', TRUE),
    ('C1048', 'acoleman', 'Amy', 'Coleman', 'amy.coleman@example.com', '+1 555-890-5678', '$2a$12$efghijk1234567890efghijklmno', TRUE),
    ('C1049', 'rjenkins', 'Robert', 'Jenkins', 'robert.jenkins@example.com', '+1 555-901-6789', '$2a$12$hijk1234567890abcdhijklmnopq', TRUE),
    ('C1050', 'amorgan', 'Amanda', 'Morgan', 'amanda.morgan@example.com', '+1 555-012-7890', '$2a$12$jk1234567890abcdefgjklmnopqr', TRUE);

-- INSERT statements for sales - 100+ sales records
INSERT INTO sales (sale_id, vehicle_id, customer_id, sale_date, sale_price, payment_method, finance_term, notes)
VALUES
-- Sales from January 2023
('S1001', 'V1004', 'C1001', '2023-01-20', 38500.00, 'finance', 60, 'Customer traded in old vehicle. $5000 down payment.'),
('S1002', 'V1006', 'C1003', '2023-01-25', 47500.00, 'cash', NULL, 'Customer paid in full.'),
('S1003', 'V1010', 'C1005', '2023-01-28', 28500.00, 'finance', 72, 'Financed through dealer. $3000 down payment.'),
('S1004', 'V1013', 'C1007', '2023-01-30', 37500.00, 'finance', 60, '$4500 down payment.'),
('S1005', 'V1017', 'C1009', '2023-01-31', 28000.00, 'finance', 48, '$3500 down payment.'),

-- Sales from February 2023
('S1006', 'V1024', 'C1011', '2023-02-03', 27500.00, 'credit', NULL, 'Customer purchased extended warranty.'),
('S1007', 'V1027', 'C1013', '2023-02-06', 25500.00, 'finance', 60, '$2000 down payment.'),
('S1008', 'V1031', 'C1015', '2023-02-10', 49000.00, 'finance', 72, '$6000 down payment.'),
('S1009', 'V1034', 'C1017', '2023-02-12', 56500.00, 'cash', NULL, 'Customer paid in full.'),
('S1010', 'V1039', 'C1019', '2023-02-15', 59500.00, 'finance', 60, '$10000 down payment.'),
('S1011', 'V1042', 'C1021', '2023-02-18', 52500.00, 'finance', 72, '$7500 down payment.'),
('S1012', 'V1045', 'C1023', '2023-02-21', 43500.00, 'finance', 60, '$5000 down payment.'),
('S1013', 'V1048', 'C1025', '2023-02-24', 45500.00, 'cash', NULL, 'Customer traded in old vehicle and paid difference in cash.'),
('S1014', 'V1051', 'C1027', '2023-02-27', 33000.00, 'finance', 48, '$4000 down payment.'),
('S1015', 'V1057', 'C1029', '2023-02-28', 28500.00, 'finance', 60, '$3000 down payment.'),

-- Sales from March 2023
('S1018', 'V1004', 'C1035', '2023-03-07', 38000.00, 'finance', 72, '$6000 down payment.'),
('S1019', 'V1006', 'C1037', '2023-03-09', 47000.00, 'cash', NULL, 'Customer paid in full.'),
('S1020', 'V1010', 'C1039', '2023-03-11', 28000.00, 'finance', 60, '$3500 down payment.'),
('S1021', 'V1013', 'C1041', '2023-03-14', 37000.00, 'finance', 48, '$5000 down payment.'),
('S1022', 'V1017', 'C1043', '2023-03-16', 27500.00, 'credit', NULL, 'Customer purchased extended warranty.'),
('S1023', 'V1024', 'C1045', '2023-03-19', 27000.00, 'finance', 60, '$3000 down payment.'),
('S1024', 'V1027', 'C1047', '2023-03-22', 25000.00, 'finance', 48, '$2500 down payment.'),
('S1025', 'V1031', 'C1049', '2023-03-24', 48500.00, 'finance', 72, '$7000 down payment.'),
('S1026', 'V1034', 'C1002', '2023-03-26', 56000.00, 'cash', NULL, 'Customer paid in full.'),
('S1027', 'V1039', 'C1004', '2023-03-29', 58500.00, 'finance', 60, '$12000 down payment.'),
('S1028', 'V1042', 'C1006', '2023-03-31', 52000.00, 'finance', 72, '$8000 down payment.'),

-- Sales from April 2023
('S1029', 'V1045', 'C1008', '2023-04-03', 43000.00, 'finance', 60, '$6000 down payment.'),
('S1030', 'V1048', 'C1010', '2023-04-05', 44500.00, 'cash', NULL, 'Customer traded in old vehicle and paid difference in cash.'),
('S1031', 'V1051', 'C1012', '2023-04-08', 32500.00, 'finance', 48, '$4500 down payment.'),
('S1032', 'V1057', 'C1014', '2023-04-11', 28000.00, 'finance', 60, '$3500 down payment.'),
('S1035', 'V1004', 'C1020', '2023-04-19', 37500.00, 'finance', 72, '$6500 down payment.'),
('S1036', 'V1006', 'C1022', '2023-04-21', 46500.00, 'cash', NULL, 'Customer paid in full.'),
('S1037', 'V1010', 'C1024', '2023-04-24', 27500.00, 'finance', 60, '$4000 down payment.'),
('S1038', 'V1013', 'C1026', '2023-04-27', 36500.00, 'finance', 48, '$5500 down payment.'),
('S1039', 'V1017', 'C1028', '2023-04-29', 27000.00, 'credit', NULL, 'Customer purchased extended warranty.'),

-- Sales from May 2023
('S1040', 'V1024', 'C1030', '2023-05-02', 26500.00, 'finance', 60, '$3500 down payment.'),
('S1041', 'V1027', 'C1032', '2023-05-05', 24500.00, 'finance', 48, '$3000 down payment.'),
('S1042', 'V1031', 'C1034', '2023-05-07', 48000.00, 'finance', 72, '$7500 down payment.'),
('S1043', 'V1034', 'C1036', '2023-05-10', 55500.00, 'cash', NULL, 'Customer paid in full.'),
('S1044', 'V1039', 'C1038', '2023-05-13', 58000.00, 'finance', 60, '$11000 down payment.'),
('S1045', 'V1042', 'C1040', '2023-05-16', 51500.00, 'finance', 72, '$8500 down payment.'),
('S1046', 'V1045', 'C1042', '2023-05-19', 42500.00, 'finance', 60, '$6500 down payment.'),
('S1047', 'V1048', 'C1044', '2023-05-22', 44000.00, 'cash', NULL, 'Customer traded in old vehicle and paid difference in cash.'),
('S1048', 'V1051', 'C1046', '2023-05-25', 32000.00, 'finance', 48, '$5000 down payment.'),
('S1049', 'V1057', 'C1048', '2023-05-28', 27500.00, 'finance', 60, '$4000 down payment.'),

-- Sales from June 2023
('S1052', 'V1004', 'C1003', '2023-06-06', 37000.00, 'finance', 72, '$7000 down payment.'),
('S1053', 'V1006', 'C1005', '2023-06-09', 46000.00, 'cash', NULL, 'Customer paid in full.'),
('S1054', 'V1010', 'C1007', '2023-06-12', 27000.00, 'finance', 60, '$4500 down payment.'),
('S1055', 'V1013', 'C1009', '2023-06-15', 36000.00, 'finance', 48, '$6000 down payment.'),
('S1056', 'V1017', 'C1011', '2023-06-18', 26500.00, 'credit', NULL, 'Customer purchased extended warranty.'),
('S1057', 'V1024', 'C1013', '2023-06-21', 26000.00, 'finance', 60, '$4000 down payment.'),
('S1058', 'V1027', 'C1015', '2023-06-24', 24000.00, 'finance', 48, '$3500 down payment.'),
('S1059', 'V1031', 'C1017', '2023-06-27', 47500.00, 'finance', 72, '$8000 down payment.'),
('S1060', 'V1034', 'C1019', '2023-06-30', 55000.00, 'cash', NULL, 'Customer paid in full.'),

-- Sales from July 2023
('S1061', 'V1039', 'C1021', '2023-07-03', 57500.00, 'finance', 60, '$11500 down payment.'),
('S1062', 'V1042', 'C1023', '2023-07-06', 51000.00, 'finance', 72, '$9000 down payment.'),
('S1063', 'V1045', 'C1025', '2023-07-09', 42000.00, 'finance', 60, '$7000 down payment.'),
('S1064', 'V1048', 'C1027', '2023-07-12', 43500.00, 'cash', NULL, 'Customer traded in old vehicle and paid difference in cash.'),
('S1065', 'V1051', 'C1029', '2023-07-15', 31500.00, 'finance', 48, '$5500 down payment.'),
('S1066', 'V1057', 'C1031', '2023-07-18', 27000.00, 'finance', 60, '$4500 down payment.'),
('S1069', 'V1004', 'C1037', '2023-07-27', 36500.00, 'finance', 72, '$7500 down payment.'),
('S1070', 'V1006', 'C1039', '2023-07-30', 45500.00, 'cash', NULL, 'Customer paid in full.'),

-- Sales from August 2023
('S1071', 'V1010', 'C1041', '2023-08-02', 26500.00, 'finance', 60, '$5000 down payment.'),
('S1072', 'V1013', 'C1043', '2023-08-05', 35500.00, 'finance', 48, '$6500 down payment.'),
('S1073', 'V1017', 'C1045', '2023-08-08', 26000.00, 'credit', NULL, 'Customer purchased extended warranty.'),
('S1074', 'V1024', 'C1047', '2023-08-11', 25500.00, 'finance', 60, '$4500 down payment.'),
('S1075', 'V1027', 'C1049', '2023-08-14', 23500.00, 'finance', 48, '$4000 down payment.'),
('S1076', 'V1031', 'C1002', '2023-08-17', 47000.00, 'finance', 72, '$8500 down payment.'),
('S1077', 'V1034', 'C1004', '2023-08-20', 54500.00, 'cash', NULL, 'Customer paid in full.'),
('S1078', 'V1039', 'C1006', '2023-08-23', 57000.00, 'finance', 60, '$12000 down payment.'),
('S1079', 'V1042', 'C1008', '2023-08-26', 50500.00, 'finance', 72, '$9500 down payment.'),
('S1080', 'V1045', 'C1010', '2023-08-29', 41500.00, 'finance', 60, '$7500 down payment.'),

-- Sales from September 2023
('S1081', 'V1048', 'C1012', '2023-09-01', 43000.00, 'cash', NULL, 'Customer traded in old vehicle and paid difference in cash.'),
('S1082', 'V1051', 'C1014', '2023-09-04', 31000.00, 'finance', 48, '$6000 down payment.'),
('S1083', 'V1057', 'C1016', '2023-09-07', 26500.00, 'finance', 60, '$5000 down payment.'),
('S1086', 'V1004', 'C1022', '2023-09-16', 36000.00, 'finance', 72, '$8000 down payment.'),
('S1087', 'V1006', 'C1024', '2023-09-19', 45000.00, 'cash', NULL, 'Customer paid in full.'),
('S1088', 'V1010', 'C1026', '2023-09-22', 26000.00, 'finance', 60, '$5500 down payment.'),
('S1089', 'V1013', 'C1028', '2023-09-25', 35000.00, 'finance', 48, '$7000 down payment.'),
('S1090', 'V1017', 'C1030', '2023-09-28', 25500.00, 'credit', NULL, 'Customer purchased extended warranty.'),

-- Sales from October 2023
('S1091', 'V1024', 'C1032', '2023-10-01', 25000.00, 'finance', 60, '$5000 down payment.'),
('S1092', 'V1027', 'C1034', '2023-10-04', 23000.00, 'finance', 48, '$4500 down payment.'),
('S1093', 'V1031', 'C1036', '2023-10-07', 46500.00, 'finance', 72, '$9000 down payment.'),
('S1094', 'V1034', 'C1038', '2023-10-10', 54000.00, 'cash', NULL, 'Customer paid in full.'),
('S1095', 'V1039', 'C1040', '2023-10-13', 56500.00, 'finance', 60, '$12500 down payment.'),
('S1096', 'V1042', 'C1042', '2023-10-16', 50000.00, 'finance', 72, '$10000 down payment.'),
('S1097', 'V1045', 'C1044', '2023-10-19', 41000.00, 'finance', 60, '$8000 down payment.'),
('S1098', 'V1048', 'C1046', '2023-10-22', 42500.00, 'cash', NULL, 'Customer traded in old vehicle and paid difference in cash.'),
('S1099', 'V1051', 'C1048', '2023-10-25', 30500.00, 'finance', 48, '$6500 down payment.'),
('S1100', 'V1057', 'C1050', '2023-10-28', 26000.00, 'finance', 60, '$5500 down payment.'),

-- Sales from November 2023
('S1103', 'V1004', 'C1005', '2023-11-07', 35500.00, 'finance', 72, '$8500 down payment.'),
('S1104', 'V1006', 'C1007', '2023-11-10', 44500.00, 'cash', NULL, 'Customer paid in full.'),
('S1105', 'V1010', 'C1009', '2023-11-13', 25500.00, 'finance', 60, '$6000 down payment.');

-- INSERT statements for service_basic_info - 30 records
INSERT INTO service_basic_info (service_id, vehicle_id, service_date, description, created_at, updated_at)
VALUES
    ('SB1001', 'V1001', '2023-02-20', 'Regular maintenance - oil change, filter replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1002', 'V1002', '2023-03-15', 'Brake pad replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1003', 'V1006', '2023-04-02', 'Engine diagnostics and tune-up', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1004', 'V1004', '2023-01-25', 'Pre-delivery inspection and detailing', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1005', 'V1008', '2023-03-10', 'Oil change and tire rotation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1006', 'V1011', '2023-04-15', 'Transmission fluid replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1007', 'V1013', '2023-02-28', 'Air conditioning service', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1008', 'V1016', '2023-03-22', 'Suspension inspection and alignment', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1009', 'V1020', '2023-04-08', 'Coolant flush and replace', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1010', 'V1022', '2023-03-05', 'Brake system flush and replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1011', 'V1025', '2023-04-12', 'Electrical system diagnosis', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1012', 'V1029', '2023-02-12', 'Spark plug replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1013', 'V1033', '2023-03-18', 'Oil change and multi-point inspection', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1014', 'V1036', '2023-04-20', 'Suspension repair - replace struts', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1015', 'V1038', '2023-02-25', 'Fuel system cleaning', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1016', 'V1042', '2023-03-30', 'Battery replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1017', 'V1045', '2023-04-05', 'Timing belt replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1018', 'V1048', '2023-03-12', 'Power steering system service', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1019', 'V1051', '2023-04-18', 'Air filter and cabin filter replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1020', 'V1054', '2023-03-25', 'Major service - 30,000 mile', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1021', 'V1057', '2023-04-22', 'Wheel bearing replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1022', 'V1007', '2023-05-05', 'Exhaust system repair', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1023', 'V1020', '2023-05-12', 'Shock absorber replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1024', 'V1036', '2023-05-18', 'Control arm bushing replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1025', 'V1054', '2023-05-25', 'Starter motor replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1026', 'V1003', '2023-06-01', 'Alternator replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1027', 'V1014', '2023-06-08', 'Radiator replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1028', 'V1023', '2023-06-15', 'Water pump replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1029', 'V1032', '2023-06-22', 'Oxygen sensor replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SB1030', 'V1040', '2023-06-29', 'Fuel pump replacement', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- INSERT statements for service_cost_info
INSERT INTO service_cost_info (service_id, cost)
VALUES
    ('SB1001', 89.99),
    ('SB1002', 249.99),
    ('SB1003', 399.99),
    ('SB1004', 149.99),
    ('SB1005', 79.99),
    ('SB1006', 199.99),
    ('SB1007', 149.99),
    ('SB1008', 129.99),
    ('SB1009', 119.99),
    ('SB1010', 189.99),
    ('SB1011', 99.99),
    ('SB1012', 179.99),
    ('SB1013', 79.99),
    ('SB1014', 429.99),
    ('SB1015', 109.99),
    ('SB1016', 159.99),
    ('SB1017', 499.99),
    ('SB1018', 149.99),
    ('SB1019', 59.99),
    ('SB1020', 349.99),
    ('SB1021', 379.99),
    ('SB1022', 259.99),
    ('SB1023', 399.99),
    ('SB1024', 299.99),
    ('SB1025', 279.99),
    ('SB1026', 329.99),
    ('SB1027', 359.99),
    ('SB1028', 289.99),
    ('SB1029', 149.99),
    ('SB1030', 399.99);

-- INSERT statements for service_technician_info
INSERT INTO service_technician_info (service_id, technician_name)
VALUES
    ('SB1001', 'Mike Johnson'),
    ('SB1002', 'Sarah Williams'),
    ('SB1003', 'David Garcia'),
    ('SB1004', 'Lisa Chen'),
    ('SB1005', 'Robert Martinez'),
    ('SB1006', 'Jennifer Lee'),
    ('SB1007', 'Thomas Wilson'),
    ('SB1008', 'Maria Rodriguez'),
    ('SB1009', 'James Taylor'),
    ('SB1010', 'Emily Brown'),
    ('SB1011', 'Michael Davis'),
    ('SB1012', 'Jessica Anderson'),
    ('SB1013', 'Christopher Martin'),
    ('SB1014', 'Amanda Thompson'),
    ('SB1015', 'Daniel White'),
    ('SB1016', 'Melissa Harris'),
    ('SB1017', 'Matthew Clark'),
    ('SB1018', 'Ashley Lewis'),
    ('SB1019', 'Andrew Walker'),
    ('SB1020', 'Stephanie Hall'),
    ('SB1021', 'Ryan Young'),
    ('SB1022', 'Lauren Allen'),
    ('SB1023', 'Joshua King'),
    ('SB1024', 'Nicole Wright'),
    ('SB1025', 'Kevin Scott'),
    ('SB1026', 'Rebecca Green'),
    ('SB1027', 'Jason Adams'),
    ('SB1028', 'Michelle Baker'),
    ('SB1029', 'Justin Nelson'),
    ('SB1030', 'Melissa Carter');



-- Test Fragmentation Rule
-- Insert data into the parent table (will be routed to fragments)
INSERT INTO vehicles (vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status)
VALUES
    ('V2222', 'Kia', 'Optima', 2022, 'KNAGM4AD7C5567890', 22000.00, 25000.00, '2023-02-20', 'in_stock'),
    ('V2221', 'Mazda', 'Mazda6', 2023, 'JM1GL1VM1J1678901', 26000.00, 29500.00, '2023-03-10', 'sold'),
    ('V2220', 'Subaru', 'Legacy', 2022, '4S3BNAF61D3789012', 24000.00, 27000.00, '2022-12-15', 'maintenance');


-- Query 1: Find all available SUVs with at least 6 seats sorted by price
SELECT s.vehicle_id, s.make, s.model, s.year, s.price, s.seating_capacity,
       s.cargo_capacity, s.ground_clearance,
       CASE WHEN s.awd_4wd THEN 'Yes' ELSE 'No' END AS all_wheel_drive
FROM suvs s
WHERE s.status = 'in_stock'
  AND s.seating_capacity >= 6
ORDER BY s.price ASC;

-- Query 2: Find top customers by sales amount
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(s.sale_id) AS number_of_purchases,
    SUM(s.sale_price) AS total_spent
FROM customers c
         JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 10;


-- Query 3: Inventory status breakdown by vehicle type

SELECT
    'Sedan' AS vehicle_type,
    status,
    COUNT(*) AS count
FROM sedans
GROUP BY status
UNION ALL
SELECT
    'SUV' AS vehicle_type,
    status,
    COUNT(*) AS count
FROM suvs
GROUP BY status
UNION ALL
SELECT
    'Truck' AS vehicle_type,
    status,
    COUNT(*) AS count
FROM trucks
GROUP BY status
ORDER BY vehicle_type, status;

-- Query 4: Calculate average price by make and model
SELECT make, model, AVG(price) as average_price, COUNT(*) as count
FROM vehicles
WHERE status = 'in_stock'
GROUP BY make, model
HAVING COUNT(*) > 1
ORDER BY average_price DESC;

-- Query 5: Comprehensive Service Report with Vehicle Details
SELECT
    sb.service_id,
    v.vehicle_id,
    v.make,
    v.model,
    v.year,
    v.vin,
    CASE
        WHEN s.sedan_id IS NOT NULL THEN 'Sedan'
        WHEN suv.suv_id IS NOT NULL THEN 'SUV'
        WHEN t.truck_id IS NOT NULL THEN 'Truck'
        ELSE 'Other'
        END AS vehicle_type,
    sb.service_date,
    sb.description,
    sc.cost,
    st.technician_name,
    EXTRACT(MONTH FROM AGE(CURRENT_DATE, sb.service_date)) AS months_since_service,
    CASE
        WHEN s.sedan_id IS NOT NULL THEN s.luxury_level::TEXT
        WHEN suv.suv_id IS NOT NULL THEN 'Seating: ' || suv.seating_capacity::TEXT
        WHEN t.truck_id IS NOT NULL THEN t.cab_type::TEXT
        ELSE NULL
        END AS additional_info,
    CASE
        WHEN EXTRACT(MONTH FROM AGE(CURRENT_DATE, sb.service_date)) > 6 THEN 'Service Due'
        ELSE 'OK'
        END AS service_status
FROM
    service_basic_info sb
        JOIN service_cost_info sc ON sb.service_id = sc.service_id
        JOIN service_technician_info st ON sb.service_id = st.service_id
        JOIN vehicles v ON sb.vehicle_id = v.vehicle_id
        LEFT JOIN sedans s ON v.vehicle_id = s.vehicle_id
        LEFT JOIN suvs suv ON v.vehicle_id = suv.vehicle_id
        LEFT JOIN trucks t ON v.vehicle_id = t.vehicle_id
WHERE
    sb.service_date BETWEEN CURRENT_DATE - INTERVAL '12 months' AND CURRENT_DATE
ORDER BY
    sb.service_date DESC,
    sc.cost DESC;