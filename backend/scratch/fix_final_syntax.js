import fs from 'fs';

// 1. Fix products.repository.js garment_rate_id -> garment_type_id for order_lines joins
const prodRepoFile = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/backend/src/modules/admin/products/products.repository.js';
let prodRepo = fs.readFileSync(prodRepoFile, 'utf8');
prodRepo = prodRepo.replace(/oi\.garment_rate_id/g, 'oi.garment_type_id');
prodRepo = prodRepo.replace(/oi_stats\.garment_rate_id/g, 'oi_stats.garment_type_id');
prodRepo = prodRepo.replace(/recent\.garment_rate_id/g, 'recent.garment_type_id');
fs.writeFileSync(prodRepoFile, prodRepo, 'utf8');
console.log('Fixed products.repository.js columns!');

// 2. Fix garment-types.repository.js WHERE clause syntax error
const gtRepoFile = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/backend/src/modules/garment-types/garment-types.repository.js';
let gtRepo = fs.readFileSync(gtRepoFile, 'utf8');
gtRepo = gtRepo.replace(/COALESCE\(p\.cost_price,\s*0\)\s*AS\s*price\s*<=\s*150/g, 'COALESCE(p.cost_price, 0) <= 150');
fs.writeFileSync(gtRepoFile, gtRepo, 'utf8');
console.log('Fixed garment-types.repository.js WHERE clause!');
