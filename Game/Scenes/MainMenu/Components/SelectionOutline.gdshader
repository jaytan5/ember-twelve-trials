shader_type canvas_item;
uniform bool highlight = false;
uniform bool hover_light = false;
uniform float saturation = 1.0;
uniform vec2 rect_size = vec2(350.0,550.0);
uniform vec4 glow_color : source_color = vec4(1.0,0.75,0.22,1.0);
uniform float padding = 30.0;
varying vec4 item_tint;

float alpha_at(sampler2D tex, vec2 p) {
 if (p.x < 0.0 || p.y < 0.0 || p.x > 1.0 || p.y > 1.0) return 0.0;
 return smoothstep(0.08,0.92,texture(tex,p).a);
}
void vertex() {
 item_tint = COLOR;
 VERTEX += (UV*2.0-1.0)*padding;
 UV = (UV*(rect_size+padding*2.0)-padding)/rect_size;
}
void fragment() {
 vec2 px = 1.0 / max(rect_size,vec2(1.0));
 vec4 art = texture(TEXTURE,clamp(UV,vec2(0.0),vec2(1.0)));
 art.a = alpha_at(TEXTURE,UV);
 art.rgb = mix(vec3(dot(art.rgb,vec3(0.299,0.587,0.114))),art.rgb,saturation);
 float shadow = alpha_at(TEXTURE,UV-vec2(3.0,8.0)*px)*0.2;
 float near_edge = 0.0;
 float soft_edge = 0.0;
 float blur_weight = 0.0;
 if (art.a < 0.999) {
 for(int i=0;i<12;i++) {
  float angle = float(i)*6.2831853/12.0;
  vec2 dir = vec2(cos(angle),sin(angle));
  shadow += alpha_at(TEXTURE,UV-(vec2(3.0,8.0)+dir*6.0)*px)/15.0;
  if(highlight || hover_light) {
   near_edge = max(near_edge,alpha_at(TEXTURE,UV+dir*2.5*px));
   // Gaussian radial integration gives a continuous falloff, not stacked outlines.
   for(int ring=1;ring<=8;ring++) {
    float radius = float(ring)*3.0;
    float weight = float(ring)*exp(-radius*radius/162.0);
    soft_edge += alpha_at(TEXTURE,UV+dir*radius*px)*weight;
    blur_weight += weight;
   }
  }
 }
 }
 float pulse = 0.88+0.12*sin(TIME*2.5);
 float sweep = pow(0.5+0.5*sin(atan((UV.y-0.5)*rect_size.y,(UV.x-0.5)*rect_size.x)*2.0-TIME*1.8),8.0);
 float strength = highlight ? pulse : 0.18;
 float halo = soft_edge/max(blur_weight,0.001);
 float glow = clamp((near_edge*0.95+halo*2.2)*strength,0.0,1.0)*(1.0-art.a);
 float shadow_a = shadow*0.42*(1.0-art.a);
 vec3 behind = vec3(0.16,0.075,0.03)*shadow_a;
 float behind_a = shadow_a;
 vec3 hue = mix(glow_color.rgb,vec3(1.0,0.96,0.71),sweep*0.55);
 behind = hue*glow+behind*(1.0-glow);
 behind_a = glow+behind_a*(1.0-glow);
 vec3 out_rgb = art.rgb*item_tint.rgb*art.a+behind*(1.0-art.a);
 float out_a = art.a+behind_a*(1.0-art.a);
 COLOR = vec4(out_rgb/max(out_a,0.0001),out_a*item_tint.a);
}
