import {CONFIG} from './config.js?v=plain1';
import {SEED} from './data.js?v=plain1';
export const KEY = 'travel:2026AutumnJapan:v1';
export function validRow(r) {
 return r && typeof r.id==='string' && /^[\w-]{1,100}$/.test(r.id) && ['event','place','like'].includes(r.kind) && r.data && typeof r.data==='object' && !Array.isArray(r.data)
 && (r.kind!=='event'||(Number.isInteger(r.data.day)&&r.data.day>=0&&r.data.day<4&&typeof r.data.title==='string'&&r.data.title.length<=300&&typeof r.data.time==='string'&&/^([01]\d|2[0-3]):[0-5]\d$/.test(r.data.time)))
 && (r.kind!=='place'||(typeof r.data.name==='string'&&r.data.name.length<=300))
 && (r.kind!=='like'||(typeof r.data.actor==='string'&&typeof r.data.placeId==='string'&&typeof r.data.on==='boolean'));
}
export class Store {
 constructor(storage=localStorage){
  this.storage=storage; this.error=''; this.listeners=[];
  this.rows=Object.fromEntries(SEED.map(r=>[r.id,{...structuredClone(r),version:1,dirty:false,deleted:false}]));
  try {const saved=JSON.parse(storage.getItem(KEY)||'null'); if(saved){if(saved.tripId!==CONFIG.tripId||!Array.isArray(saved.rows)||!saved.rows.every(validRow))throw Error('invalid');this.rows=Object.fromEntries(saved.rows.map(r=>[r.id,r]));}}catch {this.error='저장된 자료를 읽지 못했어요. 백업을 확인해 주세요.';}
 }
 list(kind){return Object.values(this.rows).filter(r=>r.kind===kind&&!r.deleted);}
 save(){try{this.storage.setItem(KEY,JSON.stringify({tripId:CONFIG.tripId,rows:Object.values(this.rows)}));this.error='';}catch {this.error='기기 저장 공간을 확인해 주세요. 백업 다운로드로 보관해 주세요.';}this.listeners.forEach(fn=>fn());}
 put(id,kind,data,deleted=false){const prev=this.rows[id];this.rows[id]={...prev,id,kind,data:structuredClone(data),deleted,version:prev?.version??0,dirty:true,change:crypto.randomUUID()};this.save();}
 merge(remote){for(const row of remote){if(!validRow(row))continue;const local=this.rows[row.id];if(!local?.dirty)this.rows[row.id]={...row,dirty:false};else if(local.version!==row.version)local.conflict=row;}this.save();}
 accept(id){const remote=this.rows[id]?.conflict;if(remote){this.rows[id]={...remote,dirty:false};this.save();}}
 keep(id){const row=this.rows[id];if(row?.conflict){row.version=row.conflict.version;delete row.conflict;row.change=crypto.randomUUID();this.save();}}
}
export function searchUrl(q){return 'https://www.google.com/maps/search/?api=1&query='+encodeURIComponent(q);}
export function directionsUrl(q){return 'https://www.google.com/maps/dir/?api=1&destination='+encodeURIComponent(q)+'&travelmode=transit';}
