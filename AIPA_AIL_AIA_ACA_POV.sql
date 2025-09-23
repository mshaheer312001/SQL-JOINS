
---- JOINS OF AP_INVOICE_LINES_V, ap_invoices_all aia, AP_INVOICE_PAYMENTS_all aipa, ap_checks_all aca, po_vendors pov

select  aia.INVOICE_DATE, aca.CHECK_DATE, aia.INVOICE_NUM, aia.DESCRIPTION, aia.INVOICE_AMOUNT,
(SELECT sum(ail.AMOUNT) FROM AP_INVOICE_LINES_V ail, AP_INVOICE_PAYMENTS_all aipa WHERE aia.INVOICE_ID = aipa.INVOICE_ID
and aipa.INVOICE_ID = ail.INVOICE_ID and ail.LINE_TYPE = 'Item' ) AS AMOUNT_PAID, ((aia.INVOICE_AMOUNT)-(SELECT sum(ail.AMOUNT) FROM AP_INVOICE_LINES_V ail, AP_INVOICE_PAYMENTS_all aipa WHERE aia.INVOICE_ID = aipa.INVOICE_ID
and aipa.INVOICE_ID = ail.INVOICE_ID and ail.LINE_TYPE = 'Item' )) AS TAX, POV.VENDOR_NAME
from ap_invoices_all aia, AP_INVOICE_PAYMENTS_all aipa, ap_checks_all aca, po_vendors pov
where 1 = 1
and aia.INVOICE_ID = aipa.INVOICE_ID
and aipa.CHECK_ID = aca.CHECK_ID
and aia.VENDOR_ID = pov.VENDOR_ID
