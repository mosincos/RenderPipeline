#pragma once

#pragma include "Includes/Configuration.inc.glsl"
#pragma include "Includes/Structures/Material.struct.glsl"
#pragma include "Includes/BRDF.inc.glsl"



float computePointLightAttenuation(float r, float d) {
    // https://imdoingitwrong.wordpress.com/2011/01/31/light-attenuation/
    // Inverse falloff
    float attenuation = 1.0 / (1.0 + 2*d/r + (d*d)/(r*r)); 

    // Cut light transition starting at 80% because the curve is exponential and never really gets 0
    // float cutoff = r * 0.7;
    // attenuation *= 1.0 - saturate((d / cutoff) - 1.0) * (0.7 / 0.3);

    float linearAttenuation = 1.0 - saturate(d / r);

    attenuation = max(0.0, attenuation * linearAttenuation);
    return attenuation;
} 

vec3 applyLight(Material m, vec3 v, vec3 l, vec3 lightColor, float attenuation, float shadow) {

    float scaled_roughness = ConvertRoughness(m.roughness);


    vec3 shadingResult = vec3(0);
        
    // Skip shadows
    if (shadow < 0.001) 
        return shadingResult;

    vec3 specularColor = mix(vec3(0), m.diffuse, m.specular);
    // specularColor = m.diffuse;
    vec3 diffuseColor = mix(m.diffuse, vec3(0), m.metallic);

    vec3 n = m.normal;
    vec3 h = normalize(l + v);

    // Precomputed dot products
    float NxL = max(0, dot(n, l));
    float LxH = max(0, dot(l, h));
    float NxV = abs(dot(n, v)) + 1e-5;
    float NxH = max(0, dot(n, h));
    float VxH = max(0, dot(v, h));

    // Diffuse contribution
    shadingResult = BRDFDiffuseNormalized(NxV, NxL, LxH, m.roughness) * NxL * lightColor * diffuseColor / M_PI;

    // Specular contribution
    float distribution = BRDFDistribution_GGX(NxH, scaled_roughness);
    float visibility = BRDFVisibilitySmithGGX(NxL, NxV, scaled_roughness);
    vec3 fresnel = BRDFSchlick( specularColor, VxH, scaled_roughness) * NxL * NxV / M_PI;

    shadingResult += (distribution * visibility * fresnel) / max(0.0001, 4.0 * NxV * max(0.001, NxL) ) * lightColor;

    return shadingResult * attenuation * shadow;
}