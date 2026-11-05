// Sonde indépendante SANS client Supabase ni écriture. À tester sur un projet NON PRODUCTIF.
// Conserver la vérification JWT de la plateforme. Ne pas remplacer ffbb-sync pour tester la sonde.
import { handleReadOnly } from "../_shared/phase2-core.mjs";
Deno.serve(async(req)=>{
  if(req.method!=="POST")return Response.json({error:"POST required"},{status:405});
  try{return await handleReadOnly(await req.json());}
  catch{return Response.json({error:"Invalid JSON",production_write:false},{status:400});}
});
