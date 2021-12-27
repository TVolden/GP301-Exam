#version 410 core

// define the number of CPs in the output patch
layout (vertices = 1) out;

// attributes of the input CPs
in VS_OUT {
   vec3 WorldPos;
   vec3 Normal;
   vec2 TexCoord;
   vec3 Tangent;
   vec3 Bitangent;
} cs_in[];

struct OutputPatch {
    vec3 WorldPos_B030;
    vec3 WorldPos_B021;
    vec3 WorldPos_B012;
    vec3 WorldPos_B003;
    vec3 WorldPos_B102;
    vec3 WorldPos_B201;
    vec3 WorldPos_B300;
    vec3 WorldPos_B210;
    vec3 WorldPos_B120;
    vec3 WorldPos_B111;

    vec3 Normal_200;
    vec3 Normal_020;
    vec3 Normal_002;
    vec3 Normal_011;
    vec3 Normal_101;
    vec3 Normal_110;

    vec3 Normal[3];
    vec2 TexCoord[3];
    vec3 Tangent[3];
    vec3 Bitangent[3];
};
// attributes of the output CPs
out patch OutputPatch oPatch;

uniform float tessellationLevel;

vec3 ProjectToPlane(vec3 Point, vec3 PlanePoint, vec3 PlaneNormal)
{
    vec3 v = Point - PlanePoint;
    float Len = dot(v, PlaneNormal);
    vec3 d = Len * PlaneNormal;
    return (Point - d);
}

float w(vec3 Pi, vec3 Pj, vec3 Ni) 
{
    return dot(Pj - Pi, Ni);
}

void CalcPositions()
{
    // Order the points so the texture works
    vec3 P1 = cs_in[2].WorldPos;
    vec3 P2 = cs_in[0].WorldPos;
    vec3 P3 = cs_in[1].WorldPos;

    vec3 N1 = cs_in[2].Normal;
    vec3 N2 = cs_in[0].Normal;
    vec3 N3 = cs_in[1].Normal;

    // vertex coefficient
    oPatch.WorldPos_B300 = P1;
    oPatch.WorldPos_B030 = P2;
    oPatch.WorldPos_B003 = P3;
    
    vec3 T = cross(N1, N2);
    oPatch.WorldPos_B210 = P1 + dot(P2 - P1, T) / 3 * T;
    
    // tangent coefficient
    //oPatch.WorldPos_B210 = (2.0 * P1 + P2 - w(P1, P1, N1) * N1) / 3.0;
    oPatch.WorldPos_B120 = (2.0 * P2 + P1 - w(P2, P1, N2) * N2) / 3.0;
    oPatch.WorldPos_B021 = (2.0 * P2 + P3 - w(P2, P3, N2) * N2) / 3.0;
    oPatch.WorldPos_B012 = (2.0 * P3 + P2 - w(P3, P2, N3) * N3) / 3.0;
    oPatch.WorldPos_B102 = (2.0 * P3 + P1 - w(P3, P1, N3) * N3) / 3.0;
    oPatch.WorldPos_B201 = (2.0 * P1 + P3 - w(P1, P3, N1) * N1) / 3.0;

    // center coefficient
    vec3 E = (oPatch.WorldPos_B210 + oPatch.WorldPos_B120 + oPatch.WorldPos_B021+
    oPatch.WorldPos_B012 + oPatch.WorldPos_B102 + oPatch.WorldPos_B201) / 6.0;
    vec3 V = (P1 + P2 + P3) / 3.0;
    oPatch.WorldPos_B111 = E + (E - V) / 2.0;
}

float v(vec3 Pi, vec3 Pj, vec3 Ni, vec3 Nj) 
{
    return 2.0 * dot(Pj - Pi, Ni - Nj) / dot(Pj - Pi, Pj - Pi);
}

void CalcNormals() 
{
    vec3 P1 = cs_in[0].WorldPos;
    vec3 P2 = cs_in[1].WorldPos;
    vec3 P3 = cs_in[2].WorldPos;

    vec3 N1 = cs_in[0].Normal;
    vec3 N2 = cs_in[1].Normal;
    vec3 N3 = cs_in[2].Normal;

    oPatch.Normal_200 = N1;
    oPatch.Normal_020 = N2;
    oPatch.Normal_002 = N3;

    vec3 h110 = N1 + N2 - v(P1, P2, N1, N2) * (P2 - P1);
    vec3 h011 = N2 + N3 - v(P2, P3, N2, N3) * (P3 - P2);
    vec3 h101 = N3 + N1 - v(P3, P1, N3, N1) * (P1 - P3);

    oPatch.Normal_110 = normalize(h110);
    oPatch.Normal_011 = normalize(h011);
    oPatch.Normal_101 = normalize(h101);
}

void main()
{
    // Set the control points of the output patch
    for (int i = 0; i < 3; i++)
    {
        oPatch.Normal[i] = cs_in[i].Normal;
        oPatch.TexCoord[i] = cs_in[i].TexCoord;
        oPatch.Tangent[i] = cs_in[i].Tangent;
        oPatch.Bitangent[i] = cs_in[i].Bitangent;
    }

    CalcPositions();
    CalcNormals();

    // Calculate the tessellation levels
    gl_TessLevelOuter[0] = tessellationLevel;
    gl_TessLevelOuter[1] = tessellationLevel;
    gl_TessLevelOuter[2] = tessellationLevel;
    gl_TessLevelInner[0] = tessellationLevel;
}