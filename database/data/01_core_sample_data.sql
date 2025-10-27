-- Core Sample Data for MedView Healthcare System
-- Sample data for patients, healthcare_providers, medical_facilities, and medical_encounters
-- Created: 2024

-- =====================================================
-- PATIENTS (100 records)
-- =====================================================
INSERT INTO patients (medical_record_number, first_name, last_name, date_of_birth, gender, phone_primary, email, city, state, zip_code, created_by) VALUES 
('MRN-2024-001001', 'Sarah', 'Johnson', '1985-03-15', 'Female', '(206) 555-0101', 'sarah.johnson@email.com', 'Seattle', 'WA', '98101', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001002', 'Michael', 'Smith', '1978-11-22', 'Male', '(425) 555-0102', 'michael.smith@email.com', 'Bellevue', 'WA', '98004', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001003', 'Jennifer', 'Davis', '1992-07-08', 'Female', '(253) 555-0103', 'jennifer.davis@email.com', 'Tacoma', 'WA', '98402', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001004', 'Robert', 'Wilson', '1965-12-03', 'Male', '(360) 555-0104', 'robert.wilson@email.com', 'Spokane', 'WA', '99201', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001005', 'Lisa', 'Chen', '1990-04-18', 'Female', '(509) 555-0105', 'lisa.chen@email.com', 'Vancouver', 'WA', '98660', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001006', 'David', 'Brown', '1973-09-25', 'Male', '(206) 555-0106', 'david.brown@email.com', 'Seattle', 'WA', '98102', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001007', 'Amanda', 'Garcia', '1988-01-14', 'Female', '(425) 555-0107', 'amanda.garcia@email.com', 'Redmond', 'WA', '98052', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001008', 'Christopher', 'Martinez', '1981-06-30', 'Male', '(253) 555-0108', 'christopher.martinez@email.com', 'Federal Way', 'WA', '98003', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001009', 'Jessica', 'Anderson', '1995-10-12', 'Female', '(360) 555-0109', 'jessica.anderson@email.com', 'Olympia', 'WA', '98501', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001010', 'Matthew', 'Taylor', '1970-05-27', 'Male', '(509) 555-0110', 'matthew.taylor@email.com', 'Yakima', 'WA', '98901', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001011', 'Ashley', 'Thomas', '1987-08-19', 'Female', '(206) 555-0111', 'ashley.thomas@email.com', 'Seattle', 'WA', '98103', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001012', 'Daniel', 'Jackson', '1976-02-11', 'Male', '(425) 555-0112', 'daniel.jackson@email.com', 'Kirkland', 'WA', '98033', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001013', 'Emily', 'White', '1993-12-05', 'Female', '(253) 555-0113', 'emily.white@email.com', 'Kent', 'WA', '98032', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001014', 'Joshua', 'Harris', '1982-04-23', 'Male', '(360) 555-0114', 'joshua.harris@email.com', 'Bellingham', 'WA', '98225', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001015', 'Megan', 'Clark', '1989-09-16', 'Female', '(509) 555-0115', 'megan.clark@email.com', 'Spokane Valley', 'WA', '99216', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001016', 'Andrew', 'Lewis', '1974-07-02', 'Male', '(206) 555-0116', 'andrew.lewis@email.com', 'Seattle', 'WA', '98104', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001017', 'Stephanie', 'Robinson', '1991-11-28', 'Female', '(425) 555-0117', 'stephanie.robinson@email.com', 'Bothell', 'WA', '98011', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001018', 'Kevin', 'Walker', '1968-03-07', 'Male', '(253) 555-0118', 'kevin.walker@email.com', 'Auburn', 'WA', '98001', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001019', 'Nicole', 'Hall', '1986-08-13', 'Female', '(360) 555-0119', 'nicole.hall@email.com', 'Everett', 'WA', '98201', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001020', 'Ryan', 'Allen', '1979-01-20', 'Male', '(509) 555-0120', 'ryan.allen@email.com', 'Richland', 'WA', '99352', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001021', 'Rachel', 'Young', '1994-06-09', 'Female', '(206) 555-0121', 'rachel.young@email.com', 'Seattle', 'WA', '98105', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001022', 'Brandon', 'King', '1977-10-15', 'Male', '(425) 555-0122', 'brandon.king@email.com', 'Sammamish', 'WA', '98074', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001023', 'Lauren', 'Wright', '1990-05-31', 'Female', '(253) 555-0123', 'lauren.wright@email.com', 'Puyallup', 'WA', '98371', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001024', 'Justin', 'Lopez', '1983-12-18', 'Male', '(360) 555-0124', 'justin.lopez@email.com', 'Lacey', 'WA', '98503', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001025', 'Samantha', 'Hill', '1988-02-24', 'Female', '(509) 555-0125', 'samantha.hill@email.com', 'Kennewick', 'WA', '99336', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001026', 'Tyler', 'Scott', '1972-09-06', 'Male', '(206) 555-0126', 'tyler.scott@email.com', 'Seattle', 'WA', '98106', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001027', 'Brittany', 'Green', '1996-04-12', 'Female', '(425) 555-0127', 'brittany.green@email.com', 'Issaquah', 'WA', '98027', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001028', 'Jonathan', 'Adams', '1975-11-03', 'Male', '(253) 555-0128', 'jonathan.adams@email.com', 'Lakewood', 'WA', '98499', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001029', 'Kimberly', 'Baker', '1987-07-29', 'Female', '(360) 555-0129', 'kimberly.baker@email.com', 'Marysville', 'WA', '98270', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001030', 'Nathan', 'Gonzalez', '1980-01-16', 'Male', '(509) 555-0130', 'nathan.gonzalez@email.com', 'Walla Walla', 'WA', '99362', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001031', 'Heather', 'Nelson', '1992-08-22', 'Female', '(206) 555-0131', 'heather.nelson@email.com', 'Seattle', 'WA', '98107', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001032', 'Aaron', 'Carter', '1971-03-10', 'Male', '(425) 555-0132', 'aaron.carter@email.com', 'Mercer Island', 'WA', '98040', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001033', 'Michelle', 'Mitchell', '1989-12-07', 'Female', '(253) 555-0133', 'michelle.mitchell@email.com', 'Renton', 'WA', '98055', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001034', 'Jeremy', 'Perez', '1984-05-14', 'Male', '(360) 555-0134', 'jeremy.perez@email.com', 'Mount Vernon', 'WA', '98273', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001035', 'Crystal', 'Roberts', '1991-10-01', 'Female', '(509) 555-0135', 'crystal.roberts@email.com', 'Moses Lake', 'WA', '98837', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001036', 'Adam', 'Turner', '1978-06-18', 'Male', '(206) 555-0136', 'adam.turner@email.com', 'Seattle', 'WA', '98108', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001037', 'Danielle', 'Phillips', '1993-02-25', 'Female', '(425) 555-0137', 'danielle.phillips@email.com', 'Woodinville', 'WA', '98072', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001038', 'Jacob', 'Campbell', '1976-09-11', 'Male', '(253) 555-0138', 'jacob.campbell@email.com', 'Burien', 'WA', '98166', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001039', 'Melissa', 'Parker', '1988-04-08', 'Female', '(360) 555-0139', 'melissa.parker@email.com', 'Centralia', 'WA', '98531', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001040', 'Zachary', 'Evans', '1981-11-24', 'Male', '(509) 555-0140', 'zachary.evans@email.com', 'Pullman', 'WA', '99163', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001041', 'Angela', 'Edwards', '1995-07-17', 'Female', '(206) 555-0141', 'angela.edwards@email.com', 'Seattle', 'WA', '98109', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001042', 'Eric', 'Collins', '1973-01-04', 'Male', '(425) 555-0142', 'eric.collins@email.com', 'Lynnwood', 'WA', '98036', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001043', 'Tiffany', 'Stewart', '1990-08-30', 'Female', '(253) 555-0143', 'tiffany.stewart@email.com', 'Des Moines', 'WA', '98198', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001044', 'Gregory', 'Sanchez', '1982-03-26', 'Male', '(360) 555-0144', 'gregory.sanchez@email.com', 'Longview', 'WA', '98632', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001045', 'Vanessa', 'Morris', '1987-12-13', 'Female', '(509) 555-0145', 'vanessa.morris@email.com', 'Ellensburg', 'WA', '98926', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001046', 'Sean', 'Rogers', '1974-05-09', 'Male', '(206) 555-0146', 'sean.rogers@email.com', 'Seattle', 'WA', '98110', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001047', 'Courtney', 'Reed', '1992-10-26', 'Female', '(425) 555-0147', 'courtney.reed@email.com', 'Mill Creek', 'WA', '98012', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001048', 'Patrick', 'Cook', '1979-06-15', 'Male', '(253) 555-0148', 'patrick.cook@email.com', 'Tukwila', 'WA', '98168', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001049', 'Lindsey', 'Bailey', '1986-01-21', 'Female', '(360) 555-0149', 'lindsey.bailey@email.com', 'Aberdeen', 'WA', '98520', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001050', 'Carl', 'Rivera', '1977-09-08', 'Male', '(509) 555-0150', 'carl.rivera@email.com', 'Wenatchee', 'WA', '98801', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001051', 'Monica', 'Cooper', '1994-04-04', 'Female', '(206) 555-0151', 'monica.cooper@email.com', 'Seattle', 'WA', '98111', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001052', 'Keith', 'Richardson', '1972-11-20', 'Male', '(425) 555-0152', 'keith.richardson@email.com', 'Mukilteo', 'WA', '98275', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001053', 'Jacqueline', 'Cox', '1989-07-07', 'Female', '(253) 555-0153', 'jacqueline.cox@email.com', 'SeaTac', 'WA', '98188', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001054', 'Marcus', 'Ward', '1983-02-14', 'Male', '(360) 555-0154', 'marcus.ward@email.com', 'Port Angeles', 'WA', '98362', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001055', 'Kristen', 'Torres', '1991-09-01', 'Female', '(509) 555-0155', 'kristen.torres@email.com', 'Pasco', 'WA', '99301', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001056', 'Victor', 'Peterson', '1975-04-28', 'Male', '(206) 555-0156', 'victor.peterson@email.com', 'Seattle', 'WA', '98112', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001057', 'Allison', 'Gray', '1996-12-15', 'Female', '(425) 555-0157', 'allison.gray@email.com', 'Shoreline', 'WA', '98133', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001058', 'Ian', 'Ramirez', '1980-08-11', 'Male', '(253) 555-0158', 'ian.ramirez@email.com', 'Normandy Park', 'WA', '98148', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001059', 'Jenna', 'James', '1985-03-19', 'Female', '(360) 555-0159', 'jenna.james@email.com', 'Chehalis', 'WA', '98532', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001060', 'Blake', 'Watson', '1978-10-05', 'Male', '(509) 555-0160', 'blake.watson@email.com', 'Cheney', 'WA', '99004', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001061', 'Kathryn', 'Brooks', '1993-05-22', 'Female', '(206) 555-0161', 'kathryn.brooks@email.com', 'Seattle', 'WA', '98113', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001062', 'Mason', 'Kelly', '1971-12-09', 'Male', '(425) 555-0162', 'mason.kelly@email.com', 'Edmonds', 'WA', '98020', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001063', 'Sierra', 'Sanders', '1988-07-16', 'Female', '(253) 555-0163', 'sierra.sanders@email.com', 'Spanaway', 'WA', '98387', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001064', 'Caleb', 'Price', '1984-02-02', 'Male', '(360) 555-0164', 'caleb.price@email.com', 'Oak Harbor', 'WA', '98277', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001065', 'Paige', 'Bennett', '1990-09-28', 'Female', '(509) 555-0165', 'paige.bennett@email.com', 'Othello', 'WA', '99344', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001066', 'Trevor', 'Wood', '1976-04-15', 'Male', '(206) 555-0166', 'trevor.wood@email.com', 'Seattle', 'WA', '98114', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001067', 'Alexis', 'Barnes', '1995-11-12', 'Female', '(425) 555-0167', 'alexis.barnes@email.com', 'Brier', 'WA', '98036', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001068', 'Corey', 'Ross', '1982-06-29', 'Male', '(253) 555-0168', 'corey.ross@email.com', 'University Place', 'WA', '98466', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001069', 'Jasmine', 'Henderson', '1987-01-06', 'Female', '(360) 555-0169', 'jasmine.henderson@email.com', 'Tumwater', 'WA', '98512', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001070', 'Garrett', 'Coleman', '1979-08-23', 'Male', '(509) 555-0170', 'garrett.coleman@email.com', 'Grandview', 'WA', '98930', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001071', 'Brooke', 'Jenkins', '1992-03-12', 'Female', '(206) 555-0171', 'brooke.jenkins@email.com', 'Seattle', 'WA', '98115', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001072', 'Dustin', 'Perry', '1974-10-18', 'Male', '(425) 555-0172', 'dustin.perry@email.com', 'Mountlake Terrace', 'WA', '98043', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001073', 'Chloe', 'Powell', '1989-05-25', 'Female', '(253) 555-0173', 'chloe.powell@email.com', 'Bonney Lake', 'WA', '98391', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001074', 'Lucas', 'Long', '1985-12-31', 'Male', '(360) 555-0174', 'lucas.long@email.com', 'Sequim', 'WA', '98382', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001075', 'Haley', 'Patterson', '1991-07-08', 'Female', '(509) 555-0175', 'haley.patterson@email.com', 'Sunnyside', 'WA', '98944', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001076', 'Ethan', 'Hughes', '1977-02-24', 'Male', '(206) 555-0176', 'ethan.hughes@email.com', 'Seattle', 'WA', '98116', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001077', 'Natalie', 'Flores', '1994-09-10', 'Female', '(425) 555-0177', 'natalie.flores@email.com', 'Bothell', 'WA', '98021', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001078', 'Hunter', 'Washington', '1981-04-17', 'Male', '(253) 555-0178', 'hunter.washington@email.com', 'Steilacoom', 'WA', '98388', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001079', 'Gabrielle', 'Butler', '1986-11-04', 'Female', '(360) 555-0179', 'gabrielle.butler@email.com', 'Kelso', 'WA', '98626', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001080', 'Owen', 'Simmons', '1983-06-21', 'Male', '(509) 555-0180', 'owen.simmons@email.com', 'Toppenish', 'WA', '98948', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001081', 'Sophia', 'Foster', '1990-01-28', 'Female', '(206) 555-0181', 'sophia.foster@email.com', 'Seattle', 'WA', '98117', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001082', 'Liam', 'Gonzales', '1975-08-14', 'Male', '(425) 555-0182', 'liam.gonzales@email.com', 'Snoqualmie', 'WA', '98065', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001083', 'Maya', 'Bryant', '1993-03-03', 'Female', '(253) 555-0183', 'maya.bryant@email.com', 'Sumner', 'WA', '98390', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001084', 'Noah', 'Alexander', '1978-10-20', 'Male', '(360) 555-0184', 'noah.alexander@email.com', 'Anacortes', 'WA', '98221', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001085', 'Isabella', 'Russell', '1988-05-07', 'Female', '(509) 555-0185', 'isabella.russell@email.com', 'Prosser', 'WA', '99350', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001086', 'Logan', 'Griffin', '1984-12-24', 'Male', '(206) 555-0186', 'logan.griffin@email.com', 'Seattle', 'WA', '98118', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001087', 'Zoe', 'Diaz', '1991-07-11', 'Female', '(425) 555-0187', 'zoe.diaz@email.com', 'Duvall', 'WA', '98019', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001088', 'Connor', 'Hayes', '1976-02-28', 'Male', '(253) 555-0188', 'connor.hayes@email.com', 'Orting', 'WA', '98360', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001089', 'Leah', 'Myers', '1995-09-15', 'Female', '(360) 555-0189', 'leah.myers@email.com', 'Ferndale', 'WA', '98248', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001090', 'Jackson', 'Ford', '1980-04-02', 'Male', '(509) 555-0190', 'jackson.ford@email.com', 'Clarkston', 'WA', '99403', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001091', 'Ava', 'Hamilton', '1987-11-19', 'Female', '(206) 555-0191', 'ava.hamilton@email.com', 'Seattle', 'WA', '98119', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001092', 'Carter', 'Graham', '1973-06-06', 'Male', '(425) 555-0192', 'carter.graham@email.com', 'Carnation', 'WA', '98014', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001093', 'Grace', 'Sullivan', '1992-01-23', 'Female', '(253) 555-0193', 'grace.sullivan@email.com', 'Enumclaw', 'WA', '98022', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001094', 'Wyatt', 'Wallace', '1979-08-10', 'Male', '(360) 555-0194', 'wyatt.wallace@email.com', 'Blaine', 'WA', '98230', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001095', 'Lily', 'Woods', '1986-03-27', 'Female', '(509) 555-0195', 'lily.woods@email.com', 'Connell', 'WA', '99326', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001096', 'Aiden', 'Cole', '1982-10-14', 'Male', '(206) 555-0196', 'aiden.cole@email.com', 'Seattle', 'WA', '98121', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001097', 'Emma', 'West', '1994-05-01', 'Female', '(425) 555-0197', 'emma.west@email.com', 'North Bend', 'WA', '98045', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001098', 'Mason', 'Jordan', '1975-12-18', 'Male', '(253) 555-0198', 'mason.jordan@email.com', 'Buckley', 'WA', '98321', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001099', 'Olivia', 'Owens', '1989-07-25', 'Female', '(360) 555-0199', 'olivia.owens@email.com', 'La Push', 'WA', '98350', '12345678-1234-1234-1234-123456789012'),
('MRN-2024-001100', 'Elijah', 'Reynolds', '1981-02-12', 'Male', '(509) 555-0200', 'elijah.reynolds@email.com', 'Dayton', 'WA', '99328', '12345678-1234-1234-1234-123456789012');

-- =====================================================
-- HEALTHCARE PROVIDERS (25 records)
-- =====================================================
INSERT INTO healthcare_providers (npi_number, first_name, last_name, title, specialty, license_number, license_state, phone, email, created_by) VALUES 
('1234567890', 'Dr. James', 'Anderson', 'MD', 'Internal Medicine', 'MD12345', 'WA', '(206) 555-1001', 'j.anderson@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567891', 'Dr. Maria', 'Rodriguez', 'MD', 'Cardiology', 'MD12346', 'WA', '(425) 555-1002', 'm.rodriguez@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567892', 'Dr. Robert', 'Kim', 'MD', 'Endocrinology', 'MD12347', 'WA', '(253) 555-1003', 'r.kim@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567893', 'Dr. Sarah', 'Thompson', 'MD', 'Family Medicine', 'MD12348', 'WA', '(360) 555-1004', 's.thompson@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567894', 'Dr. Michael', 'Chen', 'MD', 'Neurology', 'MD12349', 'WA', '(509) 555-1005', 'm.chen@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567895', 'Dr. Jennifer', 'Williams', 'MD', 'Pediatrics', 'MD12350', 'WA', '(206) 555-1006', 'j.williams@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567896', 'Dr. David', 'Johnson', 'MD', 'Orthopedics', 'MD12351', 'WA', '(425) 555-1007', 'd.johnson@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567897', 'Dr. Lisa', 'Brown', 'MD', 'Dermatology', 'MD12352', 'WA', '(253) 555-1008', 'l.brown@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567898', 'Dr. Christopher', 'Davis', 'MD', 'Emergency Medicine', 'MD12353', 'WA', '(360) 555-1009', 'c.davis@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567899', 'Dr. Amanda', 'Wilson', 'MD', 'Psychiatry', 'MD12354', 'WA', '(509) 555-1010', 'a.wilson@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567800', 'Dr. Kevin', 'Miller', 'MD', 'Radiology', 'MD12355', 'WA', '(206) 555-1011', 'k.miller@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567801', 'Dr. Rachel', 'Garcia', 'MD', 'Oncology', 'MD12356', 'WA', '(425) 555-1012', 'r.garcia@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567802', 'Dr. Daniel', 'Martinez', 'MD', 'Pulmonology', 'MD12357', 'WA', '(253) 555-1013', 'd.martinez@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567803', 'Dr. Emily', 'Taylor', 'MD', 'Gastroenterology', 'MD12358', 'WA', '(360) 555-1014', 'e.taylor@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567804', 'Dr. Matthew', 'Lee', 'MD', 'Urology', 'MD12359', 'WA', '(509) 555-1015', 'm.lee@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567805', 'Dr. Ashley', 'White', 'MD', 'Obstetrics & Gynecology', 'MD12360', 'WA', '(206) 555-1016', 'a.white@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567806', 'Dr. Joshua', 'Harris', 'MD', 'Ophthalmology', 'MD12361', 'WA', '(425) 555-1017', 'j.harris@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567807', 'Dr. Nicole', 'Clark', 'MD', 'Rheumatology', 'MD12362', 'WA', '(253) 555-1018', 'n.clark@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567808', 'Dr. Ryan', 'Lewis', 'MD', 'Anesthesiology', 'MD12363', 'WA', '(360) 555-1019', 'r.lewis@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567809', 'Dr. Stephanie', 'Robinson', 'MD', 'Pathology', 'MD12364', 'WA', '(509) 555-1020', 's.robinson@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567810', 'Dr. Andrew', 'Walker', 'MD', 'General Surgery', 'MD12365', 'WA', '(206) 555-1021', 'a.walker@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567811', 'Dr. Megan', 'Hall', 'MD', 'Infectious Disease', 'MD12366', 'WA', '(425) 555-1022', 'm.hall@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567812', 'Dr. Brandon', 'Allen', 'MD', 'Nephrology', 'MD12367', 'WA', '(253) 555-1023', 'b.allen@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567813', 'Dr. Lauren', 'Young', 'MD', 'Hematology', 'MD12368', 'WA', '(360) 555-1024', 'l.young@medview.com', '12345678-1234-1234-1234-123456789012'),
('1234567814', 'Dr. Justin', 'King', 'MD', 'Plastic Surgery', 'MD12369', 'WA', '(509) 555-1025', 'j.king@medview.com', '12345678-1234-1234-1234-123456789012');

-- =====================================================
-- MEDICAL FACILITIES (10 records)
-- =====================================================
INSERT INTO medical_facilities (facility_name, facility_type, address_line1, city, state, zip_code, phone, fax, created_by) VALUES 
('Seattle Medical Center', 'Hospital', '1234 First Avenue', 'Seattle', 'WA', '98101', '(206) 555-2001', '(206) 555-2002', '12345678-1234-1234-1234-123456789012'),
('Bellevue Family Clinic', 'Clinic', '5678 Main Street', 'Bellevue', 'WA', '98004', '(425) 555-2003', '(425) 555-2004', '12345678-1234-1234-1234-123456789012'),
('Tacoma General Hospital', 'Hospital', '9012 Pacific Avenue', 'Tacoma', 'WA', '98402', '(253) 555-2005', '(253) 555-2006', '12345678-1234-1234-1234-123456789012'),
('Spokane Specialty Center', 'Specialty Clinic', '3456 Division Street', 'Spokane', 'WA', '99201', '(509) 555-2007', '(509) 555-2008', '12345678-1234-1234-1234-123456789012'),
('Vancouver Urgent Care', 'Urgent Care', '7890 Mill Plain Boulevard', 'Vancouver', 'WA', '98660', '(360) 555-2009', '(360) 555-2010', '12345678-1234-1234-1234-123456789012'),
('Northwest Laboratory Services', 'Laboratory', '2468 Broadway', 'Seattle', 'WA', '98102', '(206) 555-2011', '(206) 555-2012', '12345678-1234-1234-1234-123456789012'),
('Eastside Imaging Center', 'Imaging Center', '1357 NE 8th Street', 'Bellevue', 'WA', '98004', '(425) 555-2013', '(425) 555-2014', '12345678-1234-1234-1234-123456789012'),
('Olympic Medical Center', 'Hospital', '939 Caroline Street', 'Port Angeles', 'WA', '98362', '(360) 555-2015', '(360) 555-2016', '12345678-1234-1234-1234-123456789012'),
('Yakima Valley Memorial', 'Hospital', '2811 Tieton Drive', 'Yakima', 'WA', '98902', '(509) 555-2017', '(509) 555-2018', '12345678-1234-1234-1234-123456789012'),
('Everett Clinic', 'Clinic', '3901 Hoyt Avenue', 'Everett', 'WA', '98201', '(425) 555-2019', '(425) 555-2020', '12345678-1234-1234-1234-123456789012');
-- =====================================================
-- MEDICAL ENCOUNTERS (50 records)
-- =====================================================
-- Note: Run this AFTER the above tables are populated
-- Using a more reliable approach with explicit subqueries

-- Create a separate script for medical encounters that can be run after the other tables are populated
-- This approach ensures all referenced records exist before creating encounters

-- Medical Encounters - Run this AFTER populating patients, providers, and facilities
DO $$
DECLARE
    patient_ids UUID[];
    provider_ids UUID[];
    facility_ids UUID[];
BEGIN
    -- Get arrays of existing IDs
    SELECT ARRAY(SELECT patient_id FROM patients ORDER BY medical_record_number LIMIT 50) INTO patient_ids;
    SELECT ARRAY(SELECT provider_id FROM healthcare_providers ORDER BY npi_number) INTO provider_ids;
    SELECT ARRAY(SELECT facility_id FROM medical_facilities ORDER BY facility_name) INTO facility_ids;
    
    -- Insert encounters using the arrays
    INSERT INTO medical_encounters (patient_id, provider_id, facility_id, encounter_type, encounter_date, chief_complaint, diagnosis_primary, encounter_status, created_by) VALUES
    (patient_ids[1], provider_ids[1], facility_ids[1], 'Outpatient', '2024-01-15 09:00:00-08', 'Annual physical exam', 'Routine health maintenance', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[2], provider_ids[2], facility_ids[2], 'Outpatient', '2024-01-16 10:30:00-08', 'Chest pain', 'Hypertension, unspecified', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[3], provider_ids[3], facility_ids[3], 'Outpatient', '2024-01-17 14:15:00-08', 'Diabetes follow-up', 'Type 2 diabetes mellitus without complications', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[4], provider_ids[4], facility_ids[4], 'Outpatient', '2024-01-18 11:00:00-08', 'Joint pain', 'Osteoarthritis of knee', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[5], provider_ids[5], facility_ids[5], 'Urgent Care', '2024-01-19 16:45:00-08', 'Headache', 'Tension headache', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[6], provider_ids[6], facility_ids[6], 'Outpatient', '2024-01-20 08:30:00-08', 'Well child visit', 'Routine child health examination', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[7], provider_ids[7], facility_ids[7], 'Outpatient', '2024-01-21 13:20:00-08', 'Back pain', 'Lower back pain', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[8], provider_ids[8], facility_ids[8], 'Outpatient', '2024-01-22 15:10:00-08', 'Skin rash', 'Contact dermatitis', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[9], provider_ids[9], facility_ids[9], 'Emergency', '2024-01-23 22:30:00-08', 'Abdominal pain', 'Acute gastritis', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[10], provider_ids[10], facility_ids[10], 'Outpatient', '2024-01-24 09:45:00-08', 'Depression screening', 'Major depressive disorder, mild', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[11], provider_ids[11], facility_ids[1], 'Outpatient', '2024-01-25 12:00:00-08', 'Chest X-ray', 'Normal chest X-ray', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[12], provider_ids[12], facility_ids[2], 'Outpatient', '2024-01-26 10:15:00-08', 'Cancer screening', 'Routine cancer screening', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[13], provider_ids[13], facility_ids[3], 'Outpatient', '2024-01-27 14:30:00-08', 'Shortness of breath', 'Asthma, unspecified', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[14], provider_ids[14], facility_ids[4], 'Outpatient', '2024-01-28 11:45:00-08', 'Stomach pain', 'Gastroesophageal reflux disease', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[15], provider_ids[15], facility_ids[5], 'Outpatient', '2024-01-29 16:00:00-08', 'Urinary symptoms', 'Urinary tract infection', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[16], provider_ids[16], facility_ids[6], 'Outpatient', '2024-01-30 08:00:00-08', 'Annual gynecologic exam', 'Routine gynecological examination', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[17], provider_ids[17], facility_ids[7], 'Outpatient', '2024-01-31 13:15:00-08', 'Eye exam', 'Routine eye examination', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[18], provider_ids[18], facility_ids[8], 'Outpatient', '2024-02-01 09:30:00-08', 'Joint stiffness', 'Rheumatoid arthritis', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[19], provider_ids[19], facility_ids[9], 'Inpatient', '2024-02-02 07:00:00-08', 'Pre-operative evaluation', 'Pre-operative examination', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[20], provider_ids[20], facility_ids[10], 'Outpatient', '2024-02-03 10:45:00-08', 'Lab work', 'Routine laboratory examination', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[21], provider_ids[21], facility_ids[1], 'Outpatient', '2024-02-04 15:20:00-08', 'Surgical consultation', 'Surgical consultation', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[22], provider_ids[22], facility_ids[2], 'Outpatient', '2024-02-05 12:30:00-08', 'Fever', 'Viral upper respiratory infection', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[23], provider_ids[23], facility_ids[3], 'Outpatient', '2024-02-06 14:00:00-08', 'Kidney function check', 'Chronic kidney disease, stage 2', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[24], provider_ids[24], facility_ids[4], 'Outpatient', '2024-02-07 11:15:00-08', 'Fatigue', 'Iron deficiency anemia', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[25], provider_ids[25], facility_ids[5], 'Outpatient', '2024-02-08 16:45:00-08', 'Cosmetic consultation', 'Cosmetic surgery consultation', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[26], provider_ids[1], facility_ids[6], 'Outpatient', '2024-02-09 08:45:00-08', 'Follow-up visit', 'Hypertension follow-up', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[27], provider_ids[2], facility_ids[7], 'Outpatient', '2024-02-10 13:30:00-08', 'Chest tightness', 'Anxiety disorder', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[28], provider_ids[3], facility_ids[8], 'Outpatient', '2024-02-11 10:00:00-08', 'Diabetes management', 'Type 2 diabetes with complications', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[29], provider_ids[4], facility_ids[9], 'Outpatient', '2024-02-12 15:15:00-08', 'Routine check-up', 'Routine health maintenance', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[30], provider_ids[5], facility_ids[10], 'Emergency', '2024-02-13 20:30:00-08', 'Severe headache', 'Migraine headache', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[31], provider_ids[6], facility_ids[1], 'Outpatient', '2024-02-14 09:20:00-08', 'Child wellness visit', 'Normal child development', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[32], provider_ids[7], facility_ids[2], 'Outpatient', '2024-02-15 14:40:00-08', 'Neck pain', 'Cervical strain', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[33], provider_ids[8], facility_ids[3], 'Outpatient', '2024-02-16 11:50:00-08', 'Skin lesion', 'Benign skin lesion', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[34], provider_ids[9], facility_ids[4], 'Emergency', '2024-02-17 18:15:00-08', 'Chest pain', 'Acute myocardial infarction', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[35], provider_ids[10], facility_ids[5], 'Outpatient', '2024-02-18 12:25:00-08', 'Mood changes', 'Bipolar disorder', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[36], provider_ids[11], facility_ids[6], 'Outpatient', '2024-02-19 16:10:00-08', 'MRI scan', 'Normal MRI findings', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[37], provider_ids[12], facility_ids[7], 'Outpatient', '2024-02-20 08:35:00-08', 'Cancer follow-up', 'Cancer surveillance', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[38], provider_ids[13], facility_ids[8], 'Outpatient', '2024-02-21 13:45:00-08', 'Cough', 'Chronic bronchitis', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[39], provider_ids[14], facility_ids[9], 'Outpatient', '2024-02-22 10:20:00-08', 'Heartburn', 'Peptic ulcer disease', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[40], provider_ids[15], facility_ids[10], 'Outpatient', '2024-02-23 15:05:00-08', 'Bladder issues', 'Overactive bladder', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[41], provider_ids[16], facility_ids[1], 'Outpatient', '2024-02-24 09:15:00-08', 'Pregnancy check', 'Normal pregnancy', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[42], provider_ids[17], facility_ids[2], 'Outpatient', '2024-02-25 14:25:00-08', 'Vision problems', 'Refractive error', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[43], provider_ids[18], facility_ids[3], 'Outpatient', '2024-02-26 11:40:00-08', 'Muscle pain', 'Fibromyalgia', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[44], provider_ids[19], facility_ids[4], 'Inpatient', '2024-02-27 06:30:00-08', 'Surgery prep', 'Pre-operative care', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[45], provider_ids[20], facility_ids[5], 'Outpatient', '2024-02-28 12:55:00-08', 'Blood work', 'Routine blood chemistry', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[46], provider_ids[21], facility_ids[6], 'Outpatient', '2024-02-29 16:20:00-08', 'Hernia evaluation', 'Inguinal hernia', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[47], provider_ids[22], facility_ids[7], 'Outpatient', '2024-03-01 08:10:00-08', 'Cold symptoms', 'Common cold', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[48], provider_ids[23], facility_ids[8], 'Outpatient', '2024-03-02 13:35:00-08', 'Kidney stones', 'Nephrolithiasis', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[49], provider_ids[24], facility_ids[9], 'Outpatient', '2024-03-03 10:50:00-08', 'Bruising', 'Thrombocytopenia', 'Completed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[50], provider_ids[25], facility_ids[10], 'Outpatient', '2024-03-04 15:30:00-08', 'Scar revision', 'Scar revision consultation', 'Completed', '12345678-1234-1234-1234-123456789012');
END $$;