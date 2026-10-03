# PayPal ERP

Stack: HTML5, CSS3, JavaScript, MySQL 8 only. No other language was added.

## Hard limitation (read first)
Browser JavaScript cannot connect to MySQL, and MySQL does not speak HTTP. Secure database connectivity with this stack alone is **not possible**: some server-side component must sit between the browser and port 3306. You excluded every language that could provide it, so none is included.

What was built instead:
- `database/` is complete and runnable: schema, triggers, stored procedure `sp_authenticate`, views, roles/permissions, demo data.
- `js/api.js` is a data layer with the **same entity names as the schema**, running in demo mode on browser localStorage. It stores no database credentials. Whatever bridge you later choose (a MySQL HTTP/REST gateway, a hosting panel API, etc.) needs only to implement `login, session, logout, list, add, update, remove` over HTTPS.
- Real security cannot live in the browser. The UI hides modules per department, but enforcement must be MySQL-side: separate DB accounts per department with GRANTs on only their tables/views, row filtering by `client_id` for clients, and `sp_authenticate` for login.

## Run
Open `index.html` (or serve the folder statically). Demo logins are on `login.html`.
Database: `mysql -h 127.0.0.1 -P 3306 -u root -p --ssl-mode=REQUIRED < database/schema.sql`, then `create_db_user.sql`, then optionally `demo_data.sql`. Remove demo rows with `remove_demo.sql`.

## Credentials
Your MySQL password was typed into a chat, so treat it as exposed and rotate it. It is intentionally **not** in any file here. Put real values in `database/db.config.example` copied to a private location outside the web root. Passwords are stored as salted SHA-256 inside MySQL (`SHA2(CONCAT(salt,pw),256)`); a slow hash such as bcrypt would need a server language, so use that when a backend exists. The owner account password `ChangeMe#2026` is temporary.

## Architecture
Browser (HTML/CSS/JS) -> [bridge, your choice, outside this stack] -> MySQL `PayPal_ERP`.
Workflow: Client -> Sales (enquiry, quotation) -> Engineering (project, design, BOQ, estimation) -> Purchase (material request, stock) -> Execution -> Accounts (invoice, payment) -> Completion. Rows link by IDs; no data is duplicated between stages.

## ER summary
clients 1-N enquiries 1-N quotations 1-N quotation_items; enquiries/quotations 1-1 projects; projects 1-N milestones, tasks, updates, members, documents, invoices, tickets, material_requests; projects 1-N boq 1-N boq_items N-1 master_items; projects 1-N estimation 1-N estimation_items N-1 master_items (trigger copies the exact master name); invoices 1-N payments; master_items 1-1 inventory_stock; roles N-M permissions; users N-1 roles/employees/clients.

## Departments and data scope
Admin/Owner: all. Sales: clients, enquiries, quotations, price list. Accounts: invoices/payments. Engineering: projects, BOQ, estimation, service tickets. Purchase: stock, material requests. Client: own rows only.

## Not included in this first build
Quotation/estimation line-item sub-forms, document upload (needs server storage), notifications UI, full report pages (the CSV export and print on every list cover basic reporting), Google Sheets live sync (export the sheet to CSV and import), and the full public pages' content. The schema already supports all of them.
