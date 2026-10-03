USE PayPal_ERP; SET FOREIGN_KEY_CHECKS=0;
DELETE FROM payments WHERE reference LIKE 'DEMO-%'; DELETE FROM invoices WHERE is_demo=1; DELETE FROM support_tickets WHERE ticket_no='TKT-001';
DELETE FROM inventory_stock; DELETE FROM boq; DELETE FROM project_milestones; DELETE FROM projects WHERE is_demo=1;
DELETE FROM master_items WHERE is_demo=1; DELETE FROM enquiries WHERE is_demo=1; DELETE FROM clients WHERE is_demo=1; DELETE FROM suppliers WHERE name LIKE 'DEMO%';
SET FOREIGN_KEY_CHECKS=1;
