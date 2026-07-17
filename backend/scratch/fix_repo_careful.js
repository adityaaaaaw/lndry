import fs from 'fs';

const file = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/backend/src/modules/garment-types/garment-types.repository.js';
let content = fs.readFileSync(file, 'utf8');

// 1. Replace table names
content = content.replace(/\bgarment_rates\b/g, 'garment_types');

// 2. Replace column selection list items carefully
content = content.replace(/\bp\.thumbnail_url\b/g, "COALESCE((p.images->>0), '') AS thumbnail_url");
content = content.replace(/\bp\.price\b/g, "COALESCE(p.cost_price, 0) AS price");
content = content.replace(/\bp\.sale_price\b/g, "COALESCE(p.cost_price, 0) AS sale_price");

// 3. Fix the combined union selection (where columns don't have p. prefix)
content = content.replace(/\bprice,\s+sale_price,\s+stock_quantity,\s+unit,\s+thumbnail_url\b/g,
  "COALESCE(cost_price, 0) AS price, COALESCE(cost_price, 0) AS sale_price, stock_quantity, unit, COALESCE((images->>0), '') AS thumbnail_url");

content = content.replace(/\bSELECT\s+id,\s+name,\s+slug,\s+price,\s+sale_price,\s+stock_quantity,\s+unit,\s+thumbnail_url\b/g,
  "SELECT id, name, slug, COALESCE(cost_price, 0) AS price, COALESCE(cost_price, 0) AS sale_price, stock_quantity, unit, COALESCE((images->>0), '') AS thumbnail_url");

// 4. Fix WHERE and ORDER BY clauses
content = content.replace(/\(p\.price\s+-\s+p\.sale_price\)\s+AS\s+discount/g, "0 AS discount");
content = content.replace(/p\.sale_price\s+IS\s+NOT\s+NULL\s+AND\s+p\.sale_price\s+<\s+p\.price/gi, "p.cost_price IS NOT NULL");
content = content.replace(/COALESCE\(p\.cost_price,\s*0\)\s*AS\s*sale_price\s+IS\s+NOT\s+NULL/gi, "p.cost_price IS NOT NULL");
content = content.replace(/p\.price\s+<=\s+150/g, "COALESCE(p.cost_price, 0) <= 150");
content = content.replace(/ORDER\s+BY\s+p\.sale_price\s+ASC/gi, "ORDER BY COALESCE(p.cost_price, 0) ASC");
content = content.replace(/ORDER\s+BY\s+COALESCE\(p\.cost_price,\s*0\)\s*AS\s*sale_price\s+ASC/gi, "ORDER BY COALESCE(p.cost_price, 0) ASC");

// 5. Fix create query columns (Line 902)
content = content.replace(
  `        (name, slug, description, price, sale_price, cost_price,
         category_id, stock_quantity, unit, thumbnail_url, images, tags,`,
  `        (name, slug, meta_description, cost_price,
         category_id, stock_quantity, unit, images, tags,`
);
// Fix values placeholders matching columns count (original 46 columns, new is 43 columns)
content = content.replace(
  `       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42,$43,$44,$45,$46)
       RETURNING id, name, slug, price, sale_price, stock_quantity, unit,
                 thumbnail_url, category_id, is_featured, is_active, sku, created_at\`,
      [
        data.name, data.slug, data.description || null,
        data.price, data.salePrice || null, data.costPrice || null,
        data.categoryId || null, data.stock || 0, data.unit || 'unit',
        data.thumbnailUrl || null, JSON.stringify(data.images || []),`,
  `       VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42,$43)
       RETURNING id, name, slug, COALESCE(cost_price, 0) AS price, COALESCE(cost_price, 0) AS sale_price, stock_quantity, unit,
                 COALESCE((images->>0), '') AS thumbnail_url, category_id, is_featured, is_active, sku, created_at\`,
      [
        data.name, data.slug, data.description || null, data.costPrice || null,
        data.categoryId || null, data.stock || 0, data.unit || 'unit',
        JSON.stringify(data.images || []),`
);

// Fix create parameters remaining array elements
content = content.replace(
  `        data.tags || [], data.isFeatured || false, data.isActive || false,
        data.sku || null, data.barcode || null, data.lowStockThreshold || 0,
        data.maxOrderQty || 99, data.ingredients || null, data.allergenInfo || null,
        data.shelfLife || null, data.storageInstructions || null, data.certifications || null,
        data.nutritionInfo || null, data.metaTitle || null, data.metaDescription || null,
        data.brand || null, data.brandLogoUrl || null, data.netQuantity || null,
        data.highlights || [], data.attributes || {}, data.vendorName || null,
        data.vendorAddress || null, data.vendorFssai || null, data.returnPolicy || null,
        data.avgRating || 0, data.ratingCount || 0, data.isAuthentic || false,
        data.productFamilyId || null, data.optionLabel || null, data.optionSortOrder || 0,
        data.isDefaultOption || false, data.foodType || 'VEG', data.originTag || null,
        data.customBadges || [], data.displayDeliveryMinutes || 0
      ]`,
  `        data.tags || [],
        data.sku || null, data.barcode || null, data.lowStockThreshold || 0,
        data.maxOrderQty || 99, data.ingredients || null, data.allergenInfo || null,
        data.shelfLife || null, data.storageInstructions || null, data.certifications || null,
        data.nutritionInfo || null, data.metaTitle || null, data.metaDescription || null,
        data.brand || null, data.brandLogoUrl || null, data.netQuantity || null,
        data.highlights || [], data.attributes || {}, data.vendorName || null,
        data.vendorAddress || null, data.vendorFssai || null, data.returnPolicy || null,
        data.avgRating || 0, data.ratingCount || 0, data.isAuthentic || false,
        data.productFamilyId || null, data.optionLabel || null, data.optionSortOrder || 0,
        data.isDefaultOption || false, data.foodType || 'VEG', data.originTag || null,
        data.customBadges || [], data.displayDeliveryMinutes || 0
      ]`
);

// Fix update query returning list (Line 1026)
content = content.replace(
  `       RETURNING id, name, slug, price, sale_price, stock_quantity, unit,
                 thumbnail_url, category_id, is_featured, is_active, updated_at`,
  `       RETURNING id, name, slug, COALESCE(cost_price, 0) AS price, COALESCE(cost_price, 0) AS sale_price, stock_quantity, unit,
                 COALESCE((images->>0), '') AS thumbnail_url, category_id, is_featured, is_active, updated_at`
);

// Fix schema mappings mapping keys
content = content.replace(`unit: 'unit', thumbnailUrl: 'thumbnail_url',`, `unit: 'unit', thumbnailUrl: "COALESCE((images->>0), '')",`);

fs.writeFileSync(file, content, 'utf8');
console.log('Fixed garment-types.repository.js carefully!');
