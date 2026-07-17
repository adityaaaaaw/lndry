import fs from 'fs';

// 1. Fix order_items -> order_lines in products.repository.js
const prodRepoFile = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/backend/src/modules/admin/products/products.repository.js';
let prodRepo = fs.readFileSync(prodRepoFile, 'utf8');
prodRepo = prodRepo.replace(/\border_items\b/g, 'order_lines');
fs.writeFileSync(prodRepoFile, prodRepo, 'utf8');
console.log('Fixed order_items in products.repository.js!');

// 2. Fix garment-types.repository.js syntax errors
const gtRepoFile = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/backend/src/modules/garment-types/garment-types.repository.js';
let gtRepo = fs.readFileSync(gtRepoFile, 'utf8');

// Fix double COALESCE replacement
gtRepo = gtRepo.replace(/COALESCE\(\(p\.images->>0\),\s*''\)\s+AS\s+COALESCE\(\(images->>0\),\s*''\)\s+AS\s+thumbnail_url/g, "COALESCE((p.images->>0), '') AS thumbnail_url");
gtRepo = gtRepo.replace(/COALESCE\(\(images->>0\),\s*''\)\s+AS\s+COALESCE\(\(images->>0\),\s*''\)\s+AS\s+thumbnail_url/g, "COALESCE((images->>0), '') AS thumbnail_url");

// Fix discount expression syntax error (deals query)
gtRepo = gtRepo.replace(/\(COALESCE\(p\.cost_price,\s*0\)\s+AS\s+price\s+-\s+COALESCE\(p\.cost_price,\s*0\)\s+AS\s+sale_price\)\s+AS\s+discount/g, "(0) AS discount");
// Fix WHERE clause syntax error (deals query)
gtRepo = gtRepo.replace(/COALESCE\(p\.cost_price,\s*0\)\s+AS\s+sale_price\s+IS\s+NOT\s+NULL/g, "p.cost_price IS NOT NULL");
gtRepo = gtRepo.replace(/COALESCE\(p\.cost_price,\s*0\)\s+AS\s+sale_price\s+<\s+COALESCE\(p\.cost_price,\s*0\)\s+AS\s+price/g, "p.cost_price < p.cost_price");

fs.writeFileSync(gtRepoFile, gtRepo, 'utf8');
console.log('Fixed syntax errors in garment-types.repository.js!');
