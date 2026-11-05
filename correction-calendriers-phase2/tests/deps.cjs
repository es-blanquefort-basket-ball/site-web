const fs=require('node:fs');const path=require('node:path');const {createRequire}=require('node:module');
const base=process.env.ESBB_TEST_DEPS || (fs.existsSync(path.join(__dirname,'node_modules'))?__dirname:'/private/tmp/esbb-sql-validation');
module.exports={base,requireDeps:createRequire(path.join(base,'package.json'))};
