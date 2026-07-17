import fs from 'fs';

// 1. Fix categories -> service_categories in products.repository.js
const prodRepoFile = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/backend/src/modules/admin/products/products.repository.js';
let prodRepo = fs.readFileSync(prodRepoFile, 'utf8');
prodRepo = prodRepo.replace(/\bJOIN categories\b/gi, 'JOIN service_categories');
prodRepo = prodRepo.replace(/\bFROM categories\b/gi, 'FROM service_categories');
fs.writeFileSync(prodRepoFile, prodRepo, 'utf8');
console.log('Fixed categories in products.repository.js!');

// 2. Fix categories -> service_categories and syntax error in garment-types.repository.js
const gtRepoFile = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/backend/src/modules/garment-types/garment-types.repository.js';
let gtRepo = fs.readFileSync(gtRepoFile, 'utf8');
gtRepo = gtRepo.replace(/\bJOIN categories\b/gi, 'JOIN service_categories');
gtRepo = gtRepo.replace(/\bFROM categories\b/gi, 'FROM service_categories');

// Fix syntax error in getPriceDrops (around line 1111)
gtRepo = gtRepo.replace(
  `              (COALESCE(p.cost_price, 0) AS price - COALESCE(p.cost_price, 0) AS sale_price) AS discount`,
  `              (0) AS discount`
);
gtRepo = gtRepo.replace(
  `         AND COALESCE(p.cost_price, 0) AS sale_price IS NOT NULL
         AND COALESCE(p.cost_price, 0) AS sale_price < COALESCE(p.cost_price, 0) AS price`,
  `         AND p.cost_price IS NOT NULL`
);

fs.writeFileSync(gtRepoFile, gtRepo, 'utf8');
console.log('Fixed categories and syntax errors in garment-types.repository.js!');
