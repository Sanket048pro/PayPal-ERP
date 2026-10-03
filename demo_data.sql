-- DEMO DATA: every row flagged is_demo=1 (or noted). Remove with remove_demo.sql
USE PayPal_ERP;
INSERT INTO clients(client_code,org_name,contact_person,email,mobile,city,state,gst_no,client_type,industry,is_demo) VALUES
('C001','Dow Chemical International','Rahul Mehta','rahul@dow.example','+91 9000000001','Mumbai','Maharashtra','27AAAAA0000A1Z5','Corporate','Chemicals',1),
('C002','Asian Paints Ltd','Neha Kulkarni','neha@asianpaints.example','+91 9000000002','Mumbai','Maharashtra','27BBBBB0000B1Z5','Corporate','Paints',1),
('C003','Sunrise Pharma Labs','Amit Shah','amit@sunrise.example','+91 9000000003','Pune','Maharashtra','27CCCCC0000C1Z5','Corporate','Pharma',1);
INSERT INTO enquiries(enquiry_no,client_id,enquiry_date,requirement,product_service,quantity,expected_date,priority,status,is_demo) VALUES
('ENQ-001',1,CURDATE()-INTERVAL 20 DAY,'R&D lab with 6 fume hoods','Laboratory setup',6,CURDATE()+INTERVAL 60 DAY,'High','Converted to Project',1),
('ENQ-002',2,CURDATE()-INTERVAL 9 DAY,'Exhaust blowers for QC lab','Blowers',4,CURDATE()+INTERVAL 30 DAY,'Medium','Quotation',1),
('ENQ-003',3,CURDATE()-INTERVAL 2 DAY,'Broen valve fittings','Fittings',40,CURDATE()+INTERVAL 20 DAY,'Low','New',1);
INSERT INTO master_items(item_code,item_name,category_id,unit_id,list_price,aliases,is_demo) VALUES
('FH-1500','FUME HOOD 1500MM POLYPROPYLENE',1,1,185000,'fh,fume cupboard,pp fume hood',1),
('BL-PP-02','PP CENTRIFUGAL BLOWER 2HP',2,1,42000,'polypropylene centrifugal blower,pp blower',1),
('BR-BV-25','BROEN BALLOREX VALVE 25MM',3,1,6800,'broen ball valve,ballorex',1),
('CB-C6-UTP','CAT6 UTP LAN CABLE',4,2,38,'cat 6 utp cable,cat-6 unshielded twisted pair',1),
('SV-INST','INSTALLATION & COMMISSIONING',5,5,95000,'install and commission,i&c',1);
INSERT INTO projects(project_no,name,client_id,enquiry_id,project_type,location,start_date,expected_end,project_value,priority,status,completion_pct,is_demo) VALUES
('PRJ-001','Dow R&D Laboratory Setup',1,1,'Lab setup','Mumbai',CURDATE()-INTERVAL 15 DAY,CURDATE()+INTERVAL 75 DAY,2450000,'High','Execution',45,1),
('PRJ-002','Asian Paints QC Exhaust Upgrade',2,2,'Blower system','Mumbai',CURDATE()-INTERVAL 5 DAY,CURDATE()+INTERVAL 40 DAY,780000,'Medium','Estimation',20,1);
INSERT INTO project_milestones(project_id,title,due_date,completed_on,status) VALUES(1,'Site survey',CURDATE()-INTERVAL 10 DAY,CURDATE()-INTERVAL 11 DAY,'Completed'),(1,'Fume hood delivery',CURDATE()+INTERVAL 15 DAY,NULL,'In Progress'),(1,'Commissioning',CURDATE()+INTERVAL 70 DAY,NULL,'Pending');
INSERT INTO boq(project_id,title) VALUES(2,'QC exhaust BOQ rev A');
INSERT INTO invoices(invoice_no,client_id,project_id,invoice_date,due_date,amount,gst_amount,status,is_demo) VALUES('INV-001',1,1,CURDATE()-INTERVAL 10 DAY,CURDATE()+INTERVAL 20 DAY,735000,132300,'Part Paid',1),('INV-002',2,2,CURDATE()-INTERVAL 40 DAY,CURDATE()-INTERVAL 10 DAY,156000,28080,'Overdue',1);
INSERT INTO payments(invoice_id,paid_on,amount,mode,reference) VALUES(1,CURDATE()-INTERVAL 5 DAY,400000,'NEFT','DEMO-REF-1');
INSERT INTO suppliers(name,contact,city) VALUES('DEMO Polyflow Industries','Suresh','Vadodara');
INSERT INTO inventory_stock(master_item_id,qty_on_hand,reorder_level) VALUES(1,3,2),(2,1,2),(3,120,50);
INSERT INTO support_tickets(ticket_no,client_id,project_id,subject,status) VALUES('TKT-001',1,1,'Blower noise on hood 3','Open');
