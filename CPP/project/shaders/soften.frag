#version 410 core

// input from rasterization
in ES_OUT {
   vec3 CamPos_tangent;
   vec3 Pos_tangent;
   vec3 LightDir_tangent;
   vec3 Norm_tangent;
   vec2 TexCoord;
   mat3 InverseTBN;
} es_out;

// light uniform variables
uniform vec3 ambientLightColor;
uniform vec3 lightColor;

// material properties
uniform float ambientOcclusionMix;
uniform float normalMappingMix;
uniform float reflectionMix;
uniform float specularExponent;

// material textures
uniform sampler2D texture_diffuse1;
uniform sampler2D texture_normal1;
uniform sampler2D texture_ambient1;
// skybox cubemap
uniform samplerCube skybox;

// output color
out vec4 FragColor;

void main()
{
   // diffuse texture sampling and material colors
   vec4 albedo = texture(texture_diffuse1, es_out.TexCoord);

   // ambient occlusion texture sampling adjusted with mix parameter
   float ambientOcclusion = texture(texture_ambient1, es_out.TexCoord).r;
   ambientOcclusion = mix(1.0, ambientOcclusion, ambientOcclusionMix);

   // fix normal range: rgb sampled value is in the range [0,1], but xyz normal vectors must be in the range [-1,1]
   vec3 N = texture(texture_normal1, es_out.TexCoord).xyz;
   N = N * 2.0f - 1.0f;

   // mix the vertex normal and the normal map texture so we can visualize the difference with it makes with a slider
   N = normalize(mix(es_out.Norm_tangent, N, normalMappingMix));

   //  the cube map has to be sampled with world space directions, rotate the normal with es_out.invTBN so that it's in world space
   vec3 tangentIncident = (es_out.Pos_tangent - es_out.CamPos_tangent);
   vec3 tangentReflect = reflect(tangentIncident, N);
   vec3 reflectionColor = texture(skybox, es_out.InverseTBN * tangentReflect).rgb;

   // LIGHTING - there are two differences in this lighting model:
   // blinn-phong reflection model instead of phong
   //   - the one using the halfway vector for the specular reflection, as presented in class
   // directinal light instead of point light
   //   - simpler as the incident light direction is a light parameter, and is not need to be computed based on surface and light positions
   //   - we dont use attenuation for directional light either

   // ambient light
   vec3 ambient = mix(ambientLightColor, reflectionColor, reflectionMix) * albedo.rgb;

   // notice that we are now using parallel light instead of a point light
   vec3 L = normalize(-es_out.LightDir_tangent);   // L: - light direction
   float diffuseModulation = max(dot(N, L), 0.0);
   vec3 diffuse = lightColor * diffuseModulation * albedo.rgb;

   // notice that we are now using the blinn-phong specular reflection
   vec3 V = normalize(es_out.CamPos_tangent - es_out.Pos_tangent); // V: surface to eye vector
   vec3 H = normalize(L + V); // H: half-vector between L and V
   float specModulation = max(dot(N, H), 0.0);
   specModulation = pow(specModulation, specularExponent);
   vec3 specular = lightColor * specModulation * reflectionColor;

   FragColor = vec4(ambient + (diffuse + specular) * ambientOcclusion, albedo.a);
}