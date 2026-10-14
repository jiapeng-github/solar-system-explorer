shader_type spatial;
render_mode unshaded;
uniform vec4 base_color : source_color = vec4(0.3,0.6,0.8,1.0);
uniform int style = 0;
uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool textured = false;
uniform bool portrait_light = false;
uniform vec3 sun_position = vec3(0.0);
varying vec3 world_normal;
varying vec3 world_position;
varying vec3 local_position;
float hash(vec3 p){p=fract(p*0.3183099+vec3(.1,.2,.3));p*=17.0;return fract(p.x*p.y*p.z*(p.x+p.y+p.z));}
float noise(vec3 p){vec3 i=floor(p);vec3 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
float fbm(vec3 p){return .55*noise(p)+.25*noise(p*2.05)+.13*noise(p*4.1)+.07*noise(p*8.2);}
void vertex(){world_normal=MODEL_NORMAL_MATRIX*NORMAL;world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;local_position=VERTEX;}
void fragment(){
 vec3 n=normalize(world_normal);
 vec3 light_dir=normalize(sun_position-world_position);
 if(portrait_light){light_dir=normalize((INV_VIEW_MATRIX*vec4(-.65,.5,.85,0.0)).xyz);}
 float diffuse=dot(n,light_dir);
 vec3 p=normalize(local_position);
 float grain=0.5;
 if(!textured){grain=fbm(p*19.0);}
 vec3 color=base_color.rgb*(.5+grain*.8);
 if(textured){color=texture(surface_map,UV).rgb;}
 else if(style==2){
  float swirl=fbm(p*9.0);
  float band=sin(UV.y*110.0+swirl*6.0);
  color=base_color.rgb*mix(.56,1.13,smoothstep(-1.0,1.0,band));
  color=mix(color,vec3(.83,.75,.62),smoothstep(.6,.9,swirl)*.45);
 }else if(style==4){color=base_color.rgb*(.73+.36*fbm(p*7.0+vec3(grain)));}
 else if(style==5){color=base_color.rgb*(.92+.08*sin(UV.y*60.0+grain*2.0));}
 float ocean=(1.0-smoothstep(.015,.045,color.r))*smoothstep(.002,.012,color.b-color.r);
 if(style==1){color=mix(color,vec3(.025,.10,.24),ocean*.5);}
 float light=smoothstep(-.19,.8,diffuse);
 vec3 lit=color*(.055+.945*light);
 if(style==1){
  float rim=pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),3.5);
  lit+=vec3(.025,.23,.55)*rim*smoothstep(-.3,.7,diffuse)*.6;
  vec3 v=normalize(CAMERA_POSITION_WORLD-world_position);
  float spec=pow(max(dot(reflect(-light_dir,n),v),0.0),45.0);
  lit+=vec3(.09,.15,.19)*spec*ocean;
 }
 if(style==3){float solar=.5+.23*sin(p.x*12.0+sin(p.y*9.0))*sin(p.z*11.0+p.y*8.0)+.12*sin((p.x+p.z)*29.0);lit=mix(vec3(1.0,.38,.008),vec3(1.0,.94,.28),smoothstep(.20,.78,solar));}
 ALBEDO=lit;
}
