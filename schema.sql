-- PayPal ERP :: MySQL 8 schema. Database: PayPal_ERP
-- mysql -h 127.0.0.1 -P 3306 -u <user> -p --ssl-mode=REQUIRED < database/schema.sql
CREATE DATABASE IF NOT EXISTS PayPal_ERP CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE PayPal_ERP;
SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE departments(id INT AUTO_INCREMENT PRIMARY KEY, code VARCHAR(20) UNIQUE NOT NULL, name VARCHAR(80) NOT NULL, status ENUM('Active','Inactive') DEFAULT 'Active', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE roles(id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(60) UNIQUE NOT NULL, department_id INT NULL, data_scope ENUM('all','department','own') NOT NULL DEFAULT 'department', FOREIGN KEY(department_id) REFERENCES departments(id));
CREATE TABLE permissions(id INT AUTO_INCREMENT PRIMARY KEY, module VARCHAR(40) NOT NULL, action ENUM('view','create','edit','delete','approve','export') NOT NULL, UNIQUE(module,action));
CREATE TABLE role_permissions(role_id INT NOT NULL, permission_id INT NOT NULL, PRIMARY KEY(role_id,permission_id), FOREIGN KEY(role_id) REFERENCES roles(id), FOREIGN KEY(permission_id) REFERENCES permissions(id));

CREATE TABLE clients(id INT AUTO_INCREMENT PRIMARY KEY, client_code VARCHAR(20) UNIQUE NOT NULL, org_name VARCHAR(150) NOT NULL, contact_person VARCHAR(100), email VARCHAR(120), mobile VARCHAR(20), alt_mobile VARCHAR(20), address TEXT, city VARCHAR(60), state VARCHAR(60), country VARCHAR(60) DEFAULT 'India', gst_no VARCHAR(20), client_type VARCHAR(40), industry VARCHAR(60), status ENUM('Active','Inactive') DEFAULT 'Active', assigned_sales_user_id INT NULL, notes TEXT, is_demo TINYINT(1) DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, INDEX(org_name), INDEX(status));
CREATE TABLE employees(id INT AUTO_INCREMENT PRIMARY KEY, emp_code VARCHAR(20) UNIQUE NOT NULL, name VARCHAR(100) NOT NULL, email VARCHAR(120), mobile VARCHAR(20), department_id INT, designation VARCHAR(60), joining_date DATE, manager_id INT NULL, status ENUM('Active','Inactive') DEFAULT 'Active', is_demo TINYINT(1) DEFAULT 0, FOREIGN KEY(department_id) REFERENCES departments(id), FOREIGN KEY(manager_id) REFERENCES employees(id));
CREATE TABLE users(id INT AUTO_INCREMENT PRIMARY KEY, email VARCHAR(120) UNIQUE NOT NULL, password_hash CHAR(64) NOT NULL, salt CHAR(32) NOT NULL, full_name VARCHAR(100) NOT NULL, mobile VARCHAR(20), role_id INT NOT NULL, employee_id INT NULL, client_id INT NULL, status ENUM('Active','Locked','Disabled') DEFAULT 'Active', failed_logins INT DEFAULT 0, last_login DATETIME NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(role_id) REFERENCES roles(id), FOREIGN KEY(employee_id) REFERENCES employees(id), FOREIGN KEY(client_id) REFERENCES clients(id));
ALTER TABLE clients ADD FOREIGN KEY(assigned_sales_user_id) REFERENCES users(id);

CREATE TABLE units(id INT AUTO_INCREMENT PRIMARY KEY, code VARCHAR(12) UNIQUE NOT NULL, name VARCHAR(40));
CREATE TABLE categories(id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(80) UNIQUE NOT NULL);
CREATE TABLE master_items(id INT AUTO_INCREMENT PRIMARY KEY, item_code VARCHAR(30) UNIQUE NOT NULL, item_name VARCHAR(200) NOT NULL, category_id INT, unit_id INT, list_price DECIMAL(14,2) DEFAULT 0, aliases VARCHAR(500) COMMENT 'comma separated abbreviations / full forms for matching', status ENUM('Active','Inactive') DEFAULT 'Active', is_demo TINYINT(1) DEFAULT 0, FOREIGN KEY(category_id) REFERENCES categories(id), FOREIGN KEY(unit_id) REFERENCES units(id), INDEX(item_name), FULLTEXT(item_name,aliases));
CREATE TABLE suppliers(id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(150) NOT NULL, contact VARCHAR(100), email VARCHAR(120), mobile VARCHAR(20), city VARCHAR(60), status ENUM('Active','Inactive') DEFAULT 'Active');

CREATE TABLE enquiries(id INT AUTO_INCREMENT PRIMARY KEY, enquiry_no VARCHAR(20) UNIQUE NOT NULL, client_id INT NOT NULL, enquiry_date DATE NOT NULL, requirement TEXT, product_service VARCHAR(150), quantity DECIMAL(12,2), expected_date DATE, priority ENUM('Low','Medium','High') DEFAULT 'Medium', assigned_user_id INT, status ENUM('New','Under Review','Quotation','Approved','Rejected','Converted to Project') DEFAULT 'New', remarks TEXT, is_demo TINYINT(1) DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY(client_id) REFERENCES clients(id), FOREIGN KEY(assigned_user_id) REFERENCES users(id), INDEX(status), INDEX(enquiry_date));
CREATE TABLE quotations(id INT AUTO_INCREMENT PRIMARY KEY, quote_no VARCHAR(20) UNIQUE NOT NULL, client_id INT NOT NULL, enquiry_id INT, quote_date DATE NOT NULL, valid_until DATE, discount_pct DECIMAL(5,2) DEFAULT 0, tax_pct DECIMAL(5,2) DEFAULT 18, total DECIMAL(14,2) DEFAULT 0, terms TEXT, prepared_by INT, approved_by INT NULL, status ENUM('Draft','Sent','Approved','Rejected','Expired') DEFAULT 'Draft', is_demo TINYINT(1) DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(client_id) REFERENCES clients(id), FOREIGN KEY(enquiry_id) REFERENCES enquiries(id), FOREIGN KEY(prepared_by) REFERENCES users(id), FOREIGN KEY(approved_by) REFERENCES users(id));
CREATE TABLE quotation_items(id INT AUTO_INCREMENT PRIMARY KEY, quotation_id INT NOT NULL, master_item_id INT NULL, description VARCHAR(250), unit_id INT, qty DECIMAL(12,2), rate DECIMAL(14,2), amount DECIMAL(14,2) GENERATED ALWAYS AS (qty*rate) STORED, FOREIGN KEY(quotation_id) REFERENCES quotations(id) ON DELETE CASCADE, FOREIGN KEY(master_item_id) REFERENCES master_items(id), FOREIGN KEY(unit_id) REFERENCES units(id));

CREATE TABLE projects(id INT AUTO_INCREMENT PRIMARY KEY, project_no VARCHAR(20) UNIQUE NOT NULL, name VARCHAR(200) NOT NULL, client_id INT NOT NULL, enquiry_id INT, quotation_id INT, po_number VARCHAR(40), project_type VARCHAR(60), scope TEXT, location VARCHAR(150), start_date DATE, expected_end DATE, manager_user_id INT, department_id INT, project_value DECIMAL(14,2) DEFAULT 0, payment_terms VARCHAR(200), priority ENUM('Low','Medium','High') DEFAULT 'Medium', status ENUM('Planning','Design','Estimation','Material','Execution','Testing','Completed','Closed') DEFAULT 'Planning', completion_pct TINYINT UNSIGNED DEFAULT 0, specifications TEXT, description TEXT, is_demo TINYINT(1) DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY(client_id) REFERENCES clients(id), FOREIGN KEY(enquiry_id) REFERENCES enquiries(id), FOREIGN KEY(quotation_id) REFERENCES quotations(id), FOREIGN KEY(manager_user_id) REFERENCES users(id), FOREIGN KEY(department_id) REFERENCES departments(id), INDEX(status), INDEX(client_id));
CREATE TABLE project_members(project_id INT, user_id INT, responsibility VARCHAR(150), PRIMARY KEY(project_id,user_id), FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE, FOREIGN KEY(user_id) REFERENCES users(id));
CREATE TABLE project_milestones(id INT AUTO_INCREMENT PRIMARY KEY, project_id INT NOT NULL, title VARCHAR(150), due_date DATE, completed_on DATE NULL, status ENUM('Pending','In Progress','Completed','Delayed') DEFAULT 'Pending', FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE);
CREATE TABLE project_tasks(id INT AUTO_INCREMENT PRIMARY KEY, project_id INT NOT NULL, title VARCHAR(200), assigned_user_id INT, due_date DATE, status ENUM('Pending','In Progress','Done') DEFAULT 'Pending', FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE, FOREIGN KEY(assigned_user_id) REFERENCES users(id));
CREATE TABLE project_updates(id INT AUTO_INCREMENT PRIMARY KEY, project_id INT NOT NULL, user_id INT, note TEXT, visible_to_client TINYINT(1) DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE, FOREIGN KEY(user_id) REFERENCES users(id));

CREATE TABLE boq(id INT AUTO_INCREMENT PRIMARY KEY, project_id INT NOT NULL, title VARCHAR(150), uploaded_by INT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(project_id) REFERENCES projects(id), FOREIGN KEY(uploaded_by) REFERENCES users(id));
CREATE TABLE boq_items(id INT AUTO_INCREMENT PRIMARY KEY, boq_id INT NOT NULL, boq_text VARCHAR(250) NOT NULL, unit VARCHAR(20), qty DECIMAL(12,2), matched_master_item_id INT NULL, match_type ENUM('Exact','Item code','Abbreviation','Full form','Approximate','None') DEFAULT 'None', confidence DECIMAL(5,2) DEFAULT 0, match_status ENUM('Suggested','Accepted','Changed','Rejected') DEFAULT 'Suggested', confirmed_by INT NULL, FOREIGN KEY(boq_id) REFERENCES boq(id) ON DELETE CASCADE, FOREIGN KEY(matched_master_item_id) REFERENCES master_items(id), FOREIGN KEY(confirmed_by) REFERENCES users(id));
CREATE TABLE estimation(id INT AUTO_INCREMENT PRIMARY KEY, est_no VARCHAR(20) UNIQUE NOT NULL, project_id INT NOT NULL, tax_pct DECIMAL(5,2) DEFAULT 18, other_charges DECIMAL(14,2) DEFAULT 0, status ENUM('Draft','Submitted','Approved','Rejected') DEFAULT 'Draft', approved_by INT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(project_id) REFERENCES projects(id), FOREIGN KEY(approved_by) REFERENCES users(id));
CREATE TABLE estimation_items(id INT AUTO_INCREMENT PRIMARY KEY, estimation_id INT NOT NULL, boq_item_id INT NULL, master_item_id INT NULL, item_code VARCHAR(30), boq_item VARCHAR(250), estimation_item VARCHAR(200) COMMENT 'always copied from master_items.item_name by trigger', description TEXT, unit_id INT, qty DECIMAL(12,2) NOT NULL DEFAULT 0, rate DECIMAL(14,2) NOT NULL DEFAULT 0, amount DECIMAL(14,2) GENERATED ALWAYS AS (qty*rate) STORED, remarks VARCHAR(250), status ENUM('Draft','Approved') DEFAULT 'Draft', FOREIGN KEY(estimation_id) REFERENCES estimation(id) ON DELETE CASCADE, FOREIGN KEY(boq_item_id) REFERENCES boq_items(id), FOREIGN KEY(master_item_id) REFERENCES master_items(id), FOREIGN KEY(unit_id) REFERENCES units(id));

CREATE TABLE material_requests(id INT AUTO_INCREMENT PRIMARY KEY, request_no VARCHAR(20) UNIQUE NOT NULL, project_id INT NOT NULL, requested_by INT, department_id INT, master_item_id INT NOT NULL, qty DECIMAL(12,2), unit_id INT, required_date DATE, priority ENUM('Low','Medium','High') DEFAULT 'Medium', status ENUM('Requested','Approved','Purchase','Received','Allocated','Completed') DEFAULT 'Requested', remarks VARCHAR(250), is_demo TINYINT(1) DEFAULT 0, FOREIGN KEY(project_id) REFERENCES projects(id), FOREIGN KEY(requested_by) REFERENCES users(id), FOREIGN KEY(master_item_id) REFERENCES master_items(id));
CREATE TABLE purchase_records(id INT AUTO_INCREMENT PRIMARY KEY, po_no VARCHAR(30) UNIQUE NOT NULL, material_request_id INT, supplier_id INT, amount DECIMAL(14,2), po_date DATE, status ENUM('Open','Received','Cancelled') DEFAULT 'Open', FOREIGN KEY(material_request_id) REFERENCES material_requests(id), FOREIGN KEY(supplier_id) REFERENCES suppliers(id));
CREATE TABLE inventory_stock(id INT AUTO_INCREMENT PRIMARY KEY, master_item_id INT NOT NULL UNIQUE, qty_on_hand DECIMAL(12,2) DEFAULT 0, reorder_level DECIMAL(12,2) DEFAULT 0, source ENUM('Manual','CSV import') DEFAULT 'Manual', updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY(master_item_id) REFERENCES master_items(id));

CREATE TABLE documents(id INT AUTO_INCREMENT PRIMARY KEY, client_id INT, project_id INT, department_id INT, doc_type ENUM('Enquiry','Quotation','PO','BOQ','Drawings','Technical','Estimation','Purchase','Project Report','Completion','Site Photo') NOT NULL, title VARCHAR(200), file_ref VARCHAR(400) COMMENT 'path/URL in protected storage', uploaded_by INT, visible_to_client TINYINT(1) DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(client_id) REFERENCES clients(id), FOREIGN KEY(project_id) REFERENCES projects(id), FOREIGN KEY(department_id) REFERENCES departments(id), FOREIGN KEY(uploaded_by) REFERENCES users(id));
CREATE TABLE invoices(id INT AUTO_INCREMENT PRIMARY KEY, invoice_no VARCHAR(20) UNIQUE NOT NULL, client_id INT NOT NULL, project_id INT, invoice_date DATE, due_date DATE, amount DECIMAL(14,2), gst_amount DECIMAL(14,2), status ENUM('Draft','Issued','Part Paid','Paid','Overdue') DEFAULT 'Issued', is_demo TINYINT(1) DEFAULT 0, FOREIGN KEY(client_id) REFERENCES clients(id), FOREIGN KEY(project_id) REFERENCES projects(id), INDEX(status));
CREATE TABLE payments(id INT AUTO_INCREMENT PRIMARY KEY, invoice_id INT NOT NULL, paid_on DATE, amount DECIMAL(14,2), mode VARCHAR(30), reference VARCHAR(80), FOREIGN KEY(invoice_id) REFERENCES invoices(id));
CREATE TABLE support_tickets(id INT AUTO_INCREMENT PRIMARY KEY, ticket_no VARCHAR(20) UNIQUE NOT NULL, client_id INT NOT NULL, project_id INT, subject VARCHAR(200), details TEXT, assigned_user_id INT, status ENUM('Open','In Progress','Resolved','Closed') DEFAULT 'Open', is_service_call TINYINT(1) DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(client_id) REFERENCES clients(id), FOREIGN KEY(project_id) REFERENCES projects(id), FOREIGN KEY(assigned_user_id) REFERENCES users(id));
CREATE TABLE notifications(id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, message VARCHAR(250), link VARCHAR(120), is_read TINYINT(1) DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(user_id) REFERENCES users(id), INDEX(user_id,is_read));
CREATE TABLE activity_logs(id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id INT, action VARCHAR(40) NOT NULL, module VARCHAR(40), record_id VARCHAR(40), details VARCHAR(400), logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX(user_id), INDEX(module,logged_at));
SET FOREIGN_KEY_CHECKS=1;

DELIMITER $$
-- Rule: Estimation Item must equal the Master Item name exactly.
CREATE TRIGGER trg_est_item_bi BEFORE INSERT ON estimation_items FOR EACH ROW
BEGIN
  IF NEW.master_item_id IS NOT NULL THEN
    SET NEW.estimation_item=(SELECT item_name FROM master_items WHERE id=NEW.master_item_id);
    SET NEW.item_code=(SELECT item_code FROM master_items WHERE id=NEW.master_item_id);
  END IF;
END$$
CREATE TRIGGER trg_est_item_bu BEFORE UPDATE ON estimation_items FOR EACH ROW
BEGIN
  IF NEW.master_item_id IS NOT NULL THEN
    SET NEW.estimation_item=(SELECT item_name FROM master_items WHERE id=NEW.master_item_id);
  END IF;
END$$
-- Login inside MySQL. Returns a row only for correct password + active account; locks after 5 failures.
CREATE PROCEDURE sp_authenticate(IN p_email VARCHAR(120), IN p_password VARCHAR(200))
BEGIN
  DECLARE v_id INT; DECLARE v_ok INT DEFAULT 0;
  SELECT id INTO v_id FROM users WHERE email=p_email AND status='Active' LIMIT 1;
  IF v_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_ok FROM users WHERE id=v_id AND password_hash=SHA2(CONCAT(salt,p_password),256);
    IF v_ok=1 THEN
      UPDATE users SET failed_logins=0,last_login=NOW() WHERE id=v_id;
      INSERT INTO activity_logs(user_id,action,module,record_id) VALUES(v_id,'Login','auth',v_id);
      SELECT u.id,u.full_name,u.email,r.name AS role,r.data_scope,d.code AS department,u.client_id
        FROM users u JOIN roles r ON r.id=u.role_id LEFT JOIN departments d ON d.id=r.department_id WHERE u.id=v_id;
    ELSE
      UPDATE users SET failed_logins=failed_logins+1, status=IF(failed_logins+1>=5,'Locked',status) WHERE id=v_id;
      INSERT INTO activity_logs(user_id,action,module,record_id) VALUES(v_id,'Login failed','auth',v_id);
    END IF;
  END IF;
END$$
DELIMITER ;

CREATE VIEW v_dash_admin AS SELECT
 (SELECT COUNT(*) FROM clients WHERE status='Active') clients,
 (SELECT COUNT(*) FROM projects WHERE status NOT IN('Completed','Closed')) active_projects,
 (SELECT COALESCE(SUM(amount),0) FROM invoices) billed,
 (SELECT COALESCE(SUM(amount),0) FROM payments) received,
 (SELECT COALESCE(SUM(amount),0) FROM purchase_records) purchases;
CREATE VIEW v_dash_sales AS SELECT
 (SELECT COUNT(*) FROM enquiries WHERE status IN('New','Under Review')) open_enquiries,
 (SELECT COUNT(*) FROM quotations WHERE status IN('Draft','Sent')) active_quotes,
 (SELECT COUNT(*) FROM projects WHERE status='Planning') new_orders;
CREATE VIEW v_invoice_dues AS SELECT i.id,i.invoice_no,i.client_id,i.amount+i.gst_amount AS gross,COALESCE(SUM(p.amount),0) AS paid,
 i.amount+i.gst_amount-COALESCE(SUM(p.amount),0) AS outstanding,i.due_date FROM invoices i LEFT JOIN payments p ON p.invoice_id=i.id GROUP BY i.id;
CREATE VIEW v_low_stock AS SELECT m.item_code,m.item_name,s.qty_on_hand,s.reorder_level FROM inventory_stock s JOIN master_items m ON m.id=s.master_item_id WHERE s.qty_on_hand<=s.reorder_level;

INSERT INTO departments(code,name) VALUES('ADMIN','Admin / Management'),('SALES','Sales & Marketing'),('ACCOUNTS','Accounts & Billing'),('ENG','Engineering / Technical'),('PURCHASE','Purchase & Inventory'),('CLIENT','Client');
INSERT INTO roles(name,department_id,data_scope) VALUES
('Super Admin',1,'all'),('Owner / Director',1,'all'),
('Sales Manager',2,'department'),('Sales Executive',2,'department'),
('Accounts Manager',3,'department'),('Accountant',3,'department'),
('Project Manager',4,'department'),('Service Engineer',4,'department'),('Technician',4,'department'),
('Purchase Manager',5,'department'),('Store Keeper',5,'department'),
('Client Company',6,'own');
INSERT INTO permissions(module,action) SELECT m.module,a.action FROM
 (SELECT 'clients' module UNION SELECT 'enquiries' UNION SELECT 'quotations' UNION SELECT 'projects' UNION SELECT 'estimation' UNION SELECT 'boq' UNION SELECT 'master_items' UNION SELECT 'materials' UNION SELECT 'inventory' UNION SELECT 'invoices' UNION SELECT 'tickets' UNION SELECT 'documents' UNION SELECT 'employees' UNION SELECT 'users') m
 CROSS JOIN (SELECT 'view' action UNION SELECT 'create' UNION SELECT 'edit' UNION SELECT 'delete' UNION SELECT 'approve' UNION SELECT 'export') a;
INSERT INTO role_permissions SELECT r.id,p.id FROM roles r JOIN permissions p WHERE r.name IN('Super Admin','Owner / Director');
INSERT INTO role_permissions SELECT r.id,p.id FROM roles r JOIN permissions p ON p.module IN('clients','enquiries','quotations','master_items') AND p.action IN('view','create','edit','export') WHERE r.department_id=2;
INSERT INTO role_permissions SELECT r.id,p.id FROM roles r JOIN permissions p ON p.module='invoices' AND p.action IN('view','create','edit','export') WHERE r.department_id=3;
INSERT INTO role_permissions SELECT r.id,p.id FROM roles r JOIN permissions p ON p.module IN('projects','estimation','boq','tickets','documents') AND p.action IN('view','create','edit') WHERE r.department_id=4;
INSERT INTO role_permissions SELECT r.id,p.id FROM roles r JOIN permissions p ON p.module IN('inventory','materials','master_items') AND p.action IN('view','create','edit','export') WHERE r.department_id=5;
INSERT INTO role_permissions SELECT r.id,p.id FROM roles r JOIN permissions p ON p.module IN('projects','invoices','tickets','enquiries','documents') AND p.action IN('view','create') WHERE r.department_id=6;

INSERT INTO units(code,name) VALUES('NOS','Numbers'),('MTR','Meter'),('SET','Set'),('KG','Kilogram'),('LS','Lump sum');
INSERT INTO categories(name) VALUES('Fume Hoods'),('Blowers'),('Fittings'),('Cables'),('Services');

-- Owner / Super Admin account. Temporary password: change at first login.
SET @salt=REPLACE(UUID(),'-','');
INSERT INTO employees(emp_code,name,email,mobile,department_id,designation,joining_date) VALUES('EMP001','Sanket Santosh Dongare','sanket048pro@gmail.com','+91 8766707195',1,'Owner / Director',CURDATE());
INSERT INTO users(email,password_hash,salt,full_name,mobile,role_id,employee_id) VALUES('sanket048pro@gmail.com',SHA2(CONCAT(@salt,'ChangeMe#2026'),256),@salt,'Sanket Santosh Dongare','+91 8766707195',1,1);
