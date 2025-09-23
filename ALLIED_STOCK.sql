SELECT inventory_item_id, description, concatenated_segments, 
       "item_code",  uom, opening_stock, avg_rate, DEMANDED_QTY, Received_Qty, Return_QTY, 
       ISSUED_QTY ,
        on_hand_qty,
       ((opening_stock)+(Received_Qty)-(Return_QTY)) as Balance_Qty, (Received_Qty * avg_rate) as Total_Value
FROM (SELECT distinct msi.inventory_item_id, msi.description,  msik.concatenated_segments, 
               msi.segment3 "item_code", msi.primary_uom_code uom,
               (SELECT NVL (SUM (mmt.transaction_quantity), 0)
                  FROM mtl_material_transactions mmt
                 WHERE mmt.inventory_item_id =
                                          msi.inventory_item_id
                   AND msi.organization_id = mmt.organization_id
                   AND TO_DATE (mmt.transaction_date) <
                                                       TO_DATE (:p_date_from))
                                                                opening_stock,
      (SELECT NVL (ROUND (cql.item_cost, 2), 0)
                  FROM cst_quantity_layers cql
                 WHERE cql.inventory_item_id =
                                            msi.inventory_item_id
                   AND cql.organization_id = msi.organization_id) AS avg_rate,
      (SELECT sum((case when mtrl.FROM_SUBINVENTORY_CODE in ('Main S (M)', 'Main S (N)', 'Main Store') then mtrl.QUANTITY else 0 end))
      FROM MTL_TXN_REQUEST_LINES mtrl
      WHERE msi.INVENTORY_ITEM_ID = mtrl.INVENTORY_ITEM_ID
           and msi.ORGANIZATION_ID = mtrl.ORGANIZATION_ID 
           AND TO_DATE(mtrl.DATE_REQUIRED) BETWEEN NVL(:p_date_from, mtrl.DATE_REQUIRED) AND NVL(:p_date_to, mtrl.DATE_REQUIRED)
      ) AS DEMANDED_QTY,
      (SELECT SUM((case when mtrl.FROM_SUBINVENTORY_CODE IN ('Main S (M)', 'Main S (N)', 'Main Store') then mtrl.QUANTITY_DELIVERED else 0 end))
      FROM MTL_TXN_REQUEST_LINES mtrl
      WHERE msi.INVENTORY_ITEM_ID = mtrl.INVENTORY_ITEM_ID
           and msi.ORGANIZATION_ID = mtrl.ORGANIZATION_ID 
           AND TO_DATE(mtrl.DATE_REQUIRED) BETWEEN NVL(:p_date_from, mtrl.DATE_REQUIRED) AND NVL(:p_date_to, mtrl.DATE_REQUIRED)
      ) AS Received_Qty,
      (SELECT SUM((case when mtrl.TO_SUBINVENTORY_CODE in ('Main S (M)', 'Main S (N)') then mtrl.QUANTITY else 0 end))
      FROM MTL_TXN_REQUEST_LINES mtrl
      WHERE msi.INVENTORY_ITEM_ID = mtrl.INVENTORY_ITEM_ID
           and msi.ORGANIZATION_ID = mtrl.ORGANIZATION_ID 
           AND TO_DATE(mtrl.DATE_REQUIRED) BETWEEN NVL(:p_date_from, mtrl.DATE_REQUIRED) AND NVL(:p_date_to, mtrl.DATE_REQUIRED)
      ) AS Return_QTY,
     ABS((SELECT SUM((case when mmt.SUBINVENTORY_CODE = 'Main Store' and mmt.TRANSACTION_TYPE_ID in ('63','64') 
--      and TRANSACTION_QUANTITY < 0
       then mmt.TRANSACTION_QUANTITY else 0 end))
      FROM mtl_material_transactions mmt
                 WHERE mmt.inventory_item_id = msi.inventory_item_id
                   AND msi.organization_id = mmt.organization_id 
           AND TO_DATE(mmt.TRANSACTION_DATE) BETWEEN NVL(:p_date_from, mmt.TRANSACTION_DATE) AND NVL(:p_date_to, mmt.TRANSACTION_DATE)
      )) AS ISSUED_QTY,
      (SELECT TO_NUMBER(SUM(NVL(mmt.TRANSACTION_QUANTITY , 0)))
         FROM MTL_MATERIAL_TRANSACTIONS mmt
         WHERE mmt.inventory_item_id = msi.inventory_item_id
           AND mmt.organization_id = msi.organization_id
           and mmt.TRANSACTION_DATE <= nvl(:p_date_to,mmt.TRANSACTION_DATE )) AS on_hand_qty
    FROM mtl_system_items msi, apps.mtl_system_items_kfv msik
             WHERE 1 = 1
           AND msi.inventory_item_id = msik.inventory_item_id
           AND msi.organization_id = msik.organization_id 
           AND msi.organization_id = NVL(:P_ORGS, msi.organization_id)
           and msik.CONCATENATED_SEGMENTS between nvl(:P_ITEM_LO,msik.CONCATENATED_SEGMENTS) and nvl(:P_ITEM_HI,msik.CONCATENATED_SEGMENTS)
--           and msik.CONCATENATED_SEGMENTS = nvl(:p_item_desc,msik.CONCATENATED_SEGMENTS)
           and msik.DESCRIPTION = nvl(:p_item_desc,msik.DESCRIPTION)
    )
    
    
    
    SELECT sum(mmt.TRANSACTION_QUANTITY) FROM  mtl_material_transactions mmt where  --move order transfer
    mmt.SUBINVENTORY_CODE = 'Main Store' and mmt.TRANSACTION_TYPE_ID in ('64') and mmt.INVENTORY_ITEM_ID = :p_id
    and mmt.ORGANIZATION_ID = :p_org 
    and to_date(mmt.TRANSACTION_DATE) between nvl(:P_ITEM_LO,mmt.TRANSACTION_DATE) and nvl(:P_ITEM_HI,mmt.TRANSACTION_DATE)
    
    
    
    
    select * from mtl_material_transactions mmt