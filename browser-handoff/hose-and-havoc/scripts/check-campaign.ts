import {runCampaign} from '../tests/campaign-player';
import {writeFileSync} from 'node:fs';
for(const seed of [2373565907,19,42,2026,7]){
 const {state,commands}=runCampaign(seed);
 console.log(JSON.stringify({seed,phase:state.phase,day:state.day,encounter:state.encounter,turn:state.turn,integrity:state.integrity,api:state.api,actions:commands.length,history:state.history}));
 writeFileSync(`qa/campaign-${seed}.json`,JSON.stringify({seed,commands,final:state},null,2));
}
