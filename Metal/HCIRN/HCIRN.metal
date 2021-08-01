//    Copyright 2005-2017 Michel Fortin
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
//  ==========================================================================
//    ADDITIONAL CONDITIONS
//    The color blindness simulation algorithm in this file is a derivative work
//    of the color_blind_sim javascript function from the Color Laboratory.
//    The original copyright and licensing terms below apply *in addition* to
//    the Apache License 2.0.
//    Original: http://colorlab.wickline.org/colorblind/colorlab/engine.js
//  --------------------------------------------------------------------------
//    The color_blind_sims() JavaScript function in the is
//    copyright (c) 2000-2001 by Matthew Wickline and the
//    Human-Computer Interaction Resource Network ( http://hcirn.com/ ).
//
//    The color_blind_sims() function is used with the permission of
//    Matthew Wickline and HCIRN, and is freely available for non-commercial
//    use. For commercial use, please contact the
//    Human-Computer Interaction Resource Network ( http://hcirn.com/ ).
//    (This notice constitutes permission for commercial use from Matthew
//    Wickline, but you must also have permission from HCIRN.)
//    Note that use of the color laboratory hosted at aware.hwg.org does
//    not constitute commercial use of the color_blind_sims()
//    function. However, use or packaging of that function (or a derivative
//    body of code) in a for-profit piece or collection of software, or text,
//    or any other for-profit work *shall* constitute commercial use.
//
//    20151129 UPDATE [by Matthew Wickline]
//        HCIRN appears to no longer exist. This makes it impractical
//        for users to obtain permission from HCIRN in order to use
//        color_blind_sims() for commercial works. Instead:
//
//        This work is licensed under a
//        Creative Commons Attribution-ShareAlike 4.0 International License.
//        http://creativecommons.org/licenses/by-sa/4.0/


#include <metal_stdlib>
using namespace metal;
#include <CoreImage/CoreImage.h>

extern "C" {

    // Dichromacy or monochromacy
    // attrib_cp_uv confusion point
    // attrib_ab_uv color axis begining point (473nm)
    // attrib_ae_uv color axis ending point (574nm), v coord
    namespace coreimage {
        float4 hcirn_kernel(sample_t color, float2 attrib_cp_uv, float2 attrib_ab_uv, float2 attrib_ae_uv, float attrib_anomalize) {

            const float4 white_xyz0 = float4(0.312713, 0.329016, 0.358271, 0.);
            const float gamma_value = 2.2;

            float3x3 xyz_from_rgb_matrix (float3(0.430574, 0.341550, 0.178325), float3(0.222015, 0.706655, 0.071330), float3(0.020183, 0.129553, 0.939180));
            float3x3 rgb_from_xyz_matrix (float3(3.063218, -1.393325, -0.475802), float3(-0.969243, 1.875966, 0.041555), float3(0.067871, -0.228834, 1.069251));

            if (attrib_anomalize <= 0.0) { // shortcut path
                // less than zero means monochromacy filter
                float m = dot(color.rgb, float3(.299, .587, .114));
                float4 newColor = mix(color, float4(m,m,m,0), -attrib_anomalize);
                return float4(newColor.rgb, color.a);
            }

            float3 c_rgb; float2 c_uv; float3 c_xyz;
            float3 s_rgb;              float4 s_xyz0;
            float3 d_rgb; float2 d_uv; float3 d_xyz;

            float2 ae_minus_ab = attrib_ae_uv - attrib_ab_uv;
            // slope of the color axis:
            float blindness_am = ae_minus_ab.y / ae_minus_ab.x;
            // "y-intercept" of axis (actually on the "v" axis at u=0)
            float blindness_ayi = attrib_ab_uv.y  -  attrib_ab_uv.x * blindness_am;

            // map RGB input into XYZ space...
            c_rgb = pow(color.rgb, float3(gamma_value, gamma_value, gamma_value));
            c_xyz = c_rgb * xyz_from_rgb_matrix;
            float sum_xyz = dot(c_xyz, float3(1., 1., 1.));

            // map into uvY space...
            c_uv = c_xyz.xy / sum_xyz;
            // find neutral grey at this luminosity (we keep the same Y value)
            float4 n_xyz0 = white_xyz0 * c_xyz.yyyy / white_xyz0.yyyy;

            float clm;  float clyi;
            float adjust;  float4 adj;

            // cl is "confusion line" between our color and the confusion point
            // clm is cl's slope, and clyi is cl's "y-intercept" (actually on the "v" axis at u=0)
            float2 cp_uv_minus_c_uv = attrib_cp_uv - c_uv;
            clm = cp_uv_minus_c_uv.y / cp_uv_minus_c_uv.x;

            clyi = dot(c_uv, float2(-clm, 1.));

            // find the change in the u and v dimensions (no Y change)
            d_uv.x = (blindness_ayi - clyi) / (clm - blindness_am);
            d_uv.y = (clm * d_uv.x) + clyi;

            // find the simulated color's XYZ coords
            float d_u_div_d_v = d_uv.x / d_uv.y;
            s_xyz0 = c_xyz.yyyy * float4(
                                         d_u_div_d_v,
                                         1.,
                                         ( 1. / d_uv.y - (d_u_div_d_v + 1.) ),
                                         0.
                                         );
            // and then try to plot the RGB coords
            s_rgb = s_xyz0.xyz * rgb_from_xyz_matrix;

            // note the RGB differences between sim color and our neutral color
            d_xyz = n_xyz0.xwz - s_xyz0.xwz;
            d_rgb = d_xyz * rgb_from_xyz_matrix;

            // find out how much to shift sim color toward neutral to fit in RGB space:
            adj.rgb = ( 1. - s_rgb ) / d_rgb;
            adj.a = 0.;

            adj = sign(1.-adj) * adj;
            adjust = max(max(0., adj.r), max(adj.g, adj.b));

            // now shift *all* three proportional to the greatest shift...
            s_rgb = s_rgb + ( adjust * d_rgb );

            // fix issue where blues were getting purple
            s_rgb = clamp(s_rgb, 0., 1.);

            // anomalize
            s_rgb = mix(c_rgb, s_rgb, attrib_anomalize);

            float3 newcolor = pow(s_rgb, float3(1./gamma_value, 1./gamma_value, 1./gamma_value));
            return float4(newcolor, color.a);
        }
    }
}
