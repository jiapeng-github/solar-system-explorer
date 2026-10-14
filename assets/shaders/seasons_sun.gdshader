shader_type canvas_item;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=(UV*2.0-1.0)*1.9;
 float r=length(p);
 float halo=exp(-max(r-1.0,0.0)*5.0)*.42;
 vec3 color=vec3(1.0,.62,.12);
 float alpha=halo*smoothstep(1.9,1.1,r);
 if(r<1.0){
  vec2 uv=p*14.0;
  float n=noise(uv)*.5+noise(uv*2.1)*.3+noise(uv*4.2)*.2;
  float filaments=pow(1.0-abs(n*2.0-1.0),7.0);
  color=mix(vec3(1.0,.33,.015),vec3(1.0,.92,.34),n*.85+filaments*.45);
  color+=vec3(.15,.22,.13)*pow(r,12.0);
  alpha=1.0;
 }
 COLOR=vec4(color,alpha);
}
