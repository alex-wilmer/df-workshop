// Use IQ's displacement function

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;


float sphereDF(vec3 pt, vec3 center, float radius) {
    float d = distance(pt, center) - radius;
    return d;
}

float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

float baseDistanceField(vec3 pt) {
    float d1 = sphereDF(pt, vec3(vec2(0.030,-0.010),-5.752), 1.);
    float d2 = sphereDF(pt, vec3(2.*sin(u_time), 0., -5.8), 1.);
    return smin(d1,d2, 7.488);
}

float displacer(vec3 pt, float k) {
    return 0.1 * sin(u_time) * sin(pt.x * k + u_time) * sin(pt.y * k) * sin(pt.z * k);
}

float distanceField(vec3 pt) {
    float d1 = baseDistanceField(pt);
    float d2 = displacer(pt, 8.416);
    return d1+d2;
}



vec3 calculateNormal(in vec3 pt) {
    vec2 eps = vec2(1.0, -1.0) * 0.0005;
    return normalize(eps.xyy * distanceField(pt + eps.xyy) +
                     eps.yyx * distanceField(pt + eps.yyx) +
                     eps.yxy * distanceField(pt + eps.yxy) +
                     eps.xxx * distanceField(pt + eps.xxx));
}

void main() {
    vec2 normalizedCoordinates = gl_FragCoord.xy/u_resolution.xy; // ((0, 1) origin at bottom left)
    normalizedCoordinates -= vec2(0.5, 0.5); // centered, (-0.5, 0.5)
    normalizedCoordinates.x *= u_resolution.x/u_resolution.y;

    vec3 rayOrigin = vec3(0, 0, 1);

    vec3 rayDirection = normalize(vec3(normalizedCoordinates, 0.) - rayOrigin);

    // March the distance field until a surface is hit.
    float distance;
    float photonPosition = 1.; // Start out (approximately) at the image plane
    float stepSizeReduction = 0.8;
    for (int i = 0; i < 256; i++) {
        distance = distanceField(rayOrigin + rayDirection * photonPosition);
        photonPosition += distance * stepSizeReduction;
        if (distance < 0.01) break;
    }
    
    if (distance < 0.01) {
        vec3 intersectionNormal = calculateNormal(rayOrigin + rayDirection * photonPosition);
        float x = intersectionNormal.x * 0.5 + 0.5;
        float y = intersectionNormal.y * -.5 + 0.5;
        gl_FragColor = vec4(x, y, 1.0,1.000);
    } else {
    	gl_FragColor = vec4(0.553,0.331,0.695,1.000);
    }
}

