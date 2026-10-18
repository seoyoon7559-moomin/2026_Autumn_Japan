import {CONFIG} from './config.js';
const SESSION_KEY='travel:2026AutumnJapan:session';
export class Sync {
 constructor(store,onStatus,config=CONFIG){this.config=config;this.store=store;this.onStatus=onStatus;this.session=null;this.busy=false;try{this.session=JSON.parse(sessionStorage.getItem(SESSION_KEY)||'null');}catch{} }
 saveSession(s){this.session=s;try{if(s)sessionStorage.setItem(SESSION_KEY,JSON.stringify(s));else sessionStorage.removeItem(SESSION_KEY);}catch{} }
 async request(path,options={}){
  const response=await fetch(this.config.supabaseUrl+path,{...options,headers:{apikey:this.config.publishableKey,'Content-Type':'application/json',...(!this.config.anonymousCollaboration&&this.session?.access_token?{Authorization:'Bearer '+this.session.access_token}:{}),...options.headers},signal:AbortSignal.timeout(15000)});
  if(!response.ok){const err=await response.json().catch(()=>({}));throw Error(response.status===401?'로그인이 만료됐어요. 다시 로그인해 주세요.':response.status===403?'이 여행의 멤버 권한을 확인해 주세요.':err.msg||err.message||'연결하지 못했어요. 기기 저장은 유지됩니다.');}
  return response.status===204?null:response.json().catch(()=>null);
 }
 async login(email){if(!this.config.collaborationEnabled)throw Error('공동 저장소 준비 후 로그인을 사용할 수 있어요.');await this.request('/auth/v1/otp?redirect_to='+encodeURIComponent(location.origin+location.pathname),{method:'POST',body:JSON.stringify({email,create_user:true})});}
 async callback(){const h=new URLSearchParams(location.hash.slice(1));if(h.has('access_token')){this.saveSession({access_token:h.get('access_token'),refresh_token:h.get('refresh_token'),expires_at:Date.now()/1000+Number(h.get('expires_in')||3600)});history.replaceState(null,'',location.pathname+location.search);}if(h.has('error_description')){const e=h.get('error_description');history.replaceState(null,'',location.pathname+location.search);throw Error(e);} }
 async refresh(){if(this.session&&(!this.session.expires_at||this.session.expires_at<Date.now()/1000+90)){const data=await this.request('/auth/v1/token?grant_type=refresh_token',{method:'POST',body:JSON.stringify({refresh_token:this.session.refresh_token})});this.saveSession({...data,expires_at:Date.now()/1000+data.expires_in});}}
 async user(){if(!this.session)return null;await this.refresh();return this.request('/auth/v1/user');}
 async logout(){try{if(this.session)await this.request('/auth/v1/logout',{method:'POST'});}finally{this.saveSession(null);this.onStatus('로그아웃 · 이 기기에 저장');}}
 async run(){
  if(!this.config.collaborationEnabled||(!this.config.anonymousCollaboration&&!this.session)||this.busy)return;
  this.busy=true;this.onStatus('동기화 중…');
  try{
   if(!this.config.anonymousCollaboration){
   await this.refresh();
   const member=await this.request('/rest/v1/autumn_trip_members?trip_id=eq.'+this.config.tripId+'&select=user_id');
   if(!member?.length)throw Error('로그인했지만 아직 여행 멤버가 아니에요. 관리자에게 멤버 등록을 요청해 주세요.');
   }
   for(const row of Object.values(this.store.rows).filter(r=>r.dirty&&!r.conflict)){
    const sent=structuredClone(row);const body={trip_id:this.config.tripId,id:sent.id,kind:sent.kind,data:sent.data,deleted:!!sent.deleted,version:sent.version+1};
    let result;
    if(sent.version===0){try{result=await this.request('/rest/v1/autumn_trip_items',{method:'POST',headers:{Prefer:'return=representation'},body:JSON.stringify(body)});}catch(e){const existing=await this.request(`/rest/v1/autumn_trip_items?trip_id=eq.${this.config.tripId}&id=eq.${encodeURIComponent(sent.id)}&select=*`);if(existing?.length){this.store.rows[sent.id].conflict=existing[0];this.store.save();continue;}throw e;}}
    else result=await this.request(`/rest/v1/autumn_trip_items?trip_id=eq.${this.config.tripId}&id=eq.${encodeURIComponent(sent.id)}&version=eq.${sent.version}`,{method:'PATCH',headers:{Prefer:'return=representation'},body:JSON.stringify(body)});
    if(!result?.length){const remote=await this.request(`/rest/v1/autumn_trip_items?trip_id=eq.${this.config.tripId}&id=eq.${encodeURIComponent(sent.id)}&select=*`);if(remote?.length)this.store.rows[sent.id].conflict=remote[0];else throw Error('공동 저장 항목이 없어요. 초기 데이터 설정을 확인해 주세요.');}
    else {const current=this.store.rows[sent.id];if(current.change===sent.change)this.store.rows[sent.id]={...result[0],dirty:false};else current.version=result[0].version;}
    this.store.save();
   }
   let remote=[],offset=0;
   for(;;){const page=await this.request(`/rest/v1/autumn_trip_items?trip_id=eq.${this.config.tripId}&select=*&order=id&limit=500&offset=${offset}`);remote.push(...page);if(page.length<500)break;offset+=500;}
   this.store.merge(remote);const conflicts=Object.values(this.store.rows).some(r=>r.conflict);const pending=Object.values(this.store.rows).some(r=>r.dirty);
   this.onStatus(conflicts?'동시 수정 확인 필요':pending?'기기 저장 · 전송 대기':'공동 저장 완료');
  }catch(e){this.onStatus(e.message);}finally{this.busy=false;}
 }
}
