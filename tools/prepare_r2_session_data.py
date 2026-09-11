"""Deterministic authored teaching fixtures, not a production game simulator."""
import hashlib
import json
import random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]


def matches(rows):
    found=set()
    for y in range(8):
        for x in range(8):
            for dx,dy in ((1,0),(0,1)):
                cells=[];xx,yy=x,y
                while xx<8 and yy<8 and rows[yy][xx]==rows[y][x]:
                    cells.append((xx,yy));xx+=dx;yy+=dy
                if len(cells)>=3: found.update(cells)
    return found


def refill(rows,removed,stream):
    for x in range(8):
        kept=[rows[y][x] for y in range(8) if (x,y) not in removed]
        added=[next(stream) for _ in range(8-len(kept))]
        for y,c in enumerate(added+kept): rows[y][x]=c


def fixture():
    rng=random.Random(9112026)
    for attempt in range(20000):
        rows=[[rng.choice('ADHT') for _ in range(8)] for _ in range(8)]
        if matches(rows): continue
        for y in range(8):
            for x in range(7):
                board=[r[:] for r in rows]; board[y][x],board[y][x+1]=board[y][x+1],board[y][x]
                wave=matches(board)
                if len(wave)!=6: continue
                stream=[rng.choice('ADHT') for _ in range(128)];it=iter(stream)
                refill(board,wave,it);second=matches(board)
                if len(second)!=3: continue
                refill(board,second,it)
                if matches(board): continue
                return {'id':'r2_two_wave_teaching','rows':[''.join(r) for r in rows],
                  'swap':[[x,y],[x+1,y]],'refill_stream':stream,'refill_order':'column left-to-right; new cells top-to-bottom',
                  'waves':[sorted(wave),sorted(second)],'final_rows':[''.join(r) for r in board],
                  'expected_casts':2,'expected_atk_damage_bank7':17,'training_only':True}
    raise RuntimeError('No validated fixture found within bound')


def build():
    old=json.loads((ROOT/'docs/assets/reference/planned/replanning/blueprint/manifest.json').read_text(encoding='utf-8'))
    extraction=json.loads((ROOT/'docs/assets/reference/planned/replanning/autocast/boss-cutout.extraction.json').read_text())
    assets={}
    for ident in ['R1-ICONS','R1-PORTRAIT','R1-ENV']:
        a=next(x for x in old['assets'] if x['id']==ident)
        assets[ident]={'path':'docs/assets/reference/planned/replanning/blueprint/'+a['path'],'regions':a['regions'],'sha256':a['sha256'],'size':a['size']}
    r2=json.loads((ROOT/'docs/design/autocast-r2-data.json').read_text(encoding='utf-8'))
    assets['R2-TILES']={k:r2['tile_asset'][k] for k in ['path','regions','sha256','size']}
    assets['R2-BOSS']={'path':'docs/assets/reference/planned/replanning/autocast/boss-cutout.png','regions':extraction['regions'],'sha256':extraction['output_sha256'],'size':extraction['size'],'pivot':[325,448],'alpha':'VERIFIED_RGBA'}
    data={'schema':'tetris-r2-complete-session-v1','rules_owner':'docs/design/REPLANNING_AUTOCAST_R2.md','state':'PREPARATION_CANDIDATE_NOT_RUNTIME',
      'assets':assets,'chain_teaching':fixture(),
      'line_teaching':{'visible_rows':['..........']*19+['DDHHTT....'],'hidden_rows':['..........']*4,'landing':[[6,19],[7,19],[8,19],[9,19]],'piece':'I','resource':'attack','expected_counts':{'A':4,'D':2,'H':2,'T':2},'initial_hp':80,'expected_hp':82,'expected_extension':0.5,'training_only':True},
      'encounter':{'id':'rift_breaker_r2_intro','player_hp':100,'boss_hp':240,'attack_bank':0,'armor':0,'ward':0,'initial_category':'ATK','initial_workspace':'LINE','seed':9112026,'repeat':True,'terminal':'HP_ZERO',
        'actions':[{'id':'probe','label':'망치 견제','seconds':10,'damage':12,'anticipation':0.6},{'id':'slam','label':'균열 강타','seconds':14,'damage':35,'anticipation':1.2},{'id':'probe','label':'망치 견제','seconds':10,'damage':12,'anticipation':0.6},{'id':'rest','label':'균열핵 안정','seconds':8,'damage':0,'anticipation':0}],
        'instance_id':'run_id:monotonic_action_index','relaxed_windup_multiplier':1.25,'commit_lead_seconds':0.001,'tuning':'UNTESTED_RECOMMENDATION'},
      'motion':{'mode':'EVENT_BOUND_KEY_POSES_WITH_TRANSFORM_TWEENS_NOT_SMOOTH_INBETWEENS','pivot':[325,448],'idle_breath':{'period':2.4,'scale_y':[1.0,1.012]},'impact_ms':120,'recovery_ms':240,'hurt_ms':100,'priority':['defeat','impact','anticipation','hurt','idle'],'no_damage_pose':'recovery','pause':'ALL_SIMULATION_FROZEN','reduced_motion':'STATIC_POSE_TEXT_SAME_TIMING'},
      'input':{'line':['Left/Right or A/D move','Z/X rotate','Down/S soft drop','Space hard drop','C hold'],'chain':['arrows move cursor','Enter select then adjacent cursor and Enter swap','mouse select two neighboring cells'],'shared':['Tab switch board at safe boundary','1/2/3 category outside cascade','Esc full pause','F1 read-only skill details full pause'],'gamepad':['Dpad move','A chain select / LINE hard drop','X/Y LINE rotate','B cancel / LINE hold','LB board switch','RB category cycle outside cascade','Start pause']},
      'line_input':{'das_ms':150,'arr_ms':50,'lock_ms':500,'lock_reset_limit':15,'gravity_seconds':1.0,'tuning':'UNTESTED_RECOMMENDATION'},
      'save_contract':{'schema':'r2-save-v1','path':'user://replanned_r2/save.json','options_path':'user://replanned_r2/options.json',
        'checkpoint':'stable CHAIN, no transaction, complete scheduler tick','restore':'full pause; clear held inputs; validate entire snapshot before applying',
        'required_groups':{
          'identity':['schema','rule_pack_hash','run_id','mode','encounter_id','elapsed_simulation_us','checkpoint_sequence'],
          'player':['hp','armor','attack_bank','ward_value','ward_target_action_instance'],
          'boss':['hp','action_sequence_index','monotonic_action_index','current_instance','eta_us','extension_used_us','committed'],
          'line':['visible_cells','hidden_cells','active_shape','active_resource','active_x','active_y','active_rotation','gravity_accumulator_us','grounded_us','lock_reset_count','grounded','hold_shape','hold_resource','hold_available','next_queue','shape_bag_remaining','resource_bag_remaining','shape_rng_state','resource_rng_state'],
          'chain':['cells','chain_rng_state','chain_id','wave_index','category_snapshot','processed_event_ids','next_wave_remaining_us'],
          'ui':['active_workspace','selected_category','last_cast','metrics'],
          'options':['schema','language','font_scale','reduced_motion','audio','keyboard_mapping','gamepad_mapping']},
        'invariants':['HP within configured maxima','ETA nonnegative; extension <= action cap','ward target equals current action instance or ward is zero','stable chain; wave_index=0; next_wave_remaining_us=0; no pending transaction','active piece valid or explicit terminal top-out; exactly five NEXT items','all three RNG states and bag orders present','committed consistent with ETA boundary; sequence and instance index match encounter','rule_pack_hash and schema match; reject partial or foreign saves'],
        'checksum':'SHA256 of UTF-8 canonical JSON payload: keys sorted recursively, compact separators, integer numeric fields; exclude checksum field',
        'atomicity':'write temp, flush, validate checksum, preserve previous valid backup, atomic replace; never load temp',
        'cancel_selection':'CHAIN same-cell selection cancels; pause retains cursor but restore clears incomplete selection'},
      'asset_approval':'PENDING_FINAL_USER_REVIEW','runtime':'NOT_RUN_USER_DEFERRED','human':'NOT_RUN'}
    p=ROOT/'docs/design/r2-complete-session.json';p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'fixture':data['chain_teaching'],'asset_count':len(assets)},ensure_ascii=False))


if __name__=='__main__': build()
