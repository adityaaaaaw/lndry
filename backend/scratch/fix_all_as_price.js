import fs from 'fs';

const gtRepoFile = 'c:/Users/ADITYA/OneDrive/Documents/shotlin/backend/src/modules/garment-types/garment-types.repository.js';
let gtRepo = fs.readFileSync(gtRepoFile, 'utf8');

// 1. Fix WHERE clause range filters
gtRepo = gtRepo.replace(/COALESCE\(p\.cost_price,\s*0\)\s+AS\s+price\s+>=/g, "COALESCE(p.cost_price, 0) >=");
gtRepo = gtRepo.replace(/COALESCE\(p\.cost_price,\s*0\)\s+AS\s+price\s+<=/g, "COALESCE(p.cost_price, 0) <=");

// 2. Fix order mapping dictionary values
gtRepo = gtRepo.replace(/COALESCE\(p\.cost_price,\s*0\)\s+AS\s+price\s+ASC/g, "COALESCE(p.cost_price, 0) ASC");
gtRepo = gtRepo.replace(/COALESCE\(p\.cost_price,\s*0\)\s+AS\s+price\s+DESC/g, "COALESCE(p.cost_price, 0) DESC");

// 3. Fix combined selection list (line 392 - wait, that was correct as alias in SELECT, but what about the CTE selection?)
// Let's verify line 329, 356, etc.
// If it is inside SELECT, AS price is correct! Only in WHERE and ORDER BY it is invalid.

fs.writeFileSync(gtRepoFile, gtRepo, 'utf8');
console.log('Successfully fixed AS price syntax errors!');
