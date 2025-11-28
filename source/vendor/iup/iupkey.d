module vendor.iup.iupkey;

extern (C)
{
    enum
    {

        K_SP = ' ',
        K_exclam = '!',
        K_quotedbl = '\"',
        K_numbersign = '#',
        K_dollar = '$',
        K_percent = '%',
        K_ampersand = '&',
        K_apostrophe = '\'',
        K_parentleft = '(',
        K_parentright = ')',
        K_asterisk = '*',
        K_plus = '+',
        K_comma = ',',
        K_minus = '-',
        K_period = '.',
        K_slash = '/',
        K_0 = '0',
        K_1 = '1',
        K_2 = '2',
        K_3 = '3',
        K_4 = '4',
        K_5 = '5',
        K_6 = '6',
        K_7 = '7',
        K_8 = '8',
        K_9 = '9',
        K_colon = ':',
        K_semicolon = ';',
        K_less = '<',
        K_equal = '=',
        K_greater = '>',
        K_question = '?',
        K_at = '@',
        K_A = 'A',
        K_B = 'B',
        K_C = 'C',
        K_D = 'D',
        K_E = 'E',
        K_F = 'F',
        K_G = 'G',
        K_H = 'H',
        K_I = 'I',
        K_J = 'J',
        K_K = 'K',
        K_L = 'L',
        K_M = 'M',
        K_N = 'N',
        K_O = 'O',
        K_P = 'P',
        K_Q = 'Q',
        K_R = 'R',
        K_S = 'S',
        K_T = 'T',
        K_U = 'U',
        K_V = 'V',
        K_W = 'W',
        K_X = 'X',
        K_Y = 'Y',
        K_Z = 'Z',
        K_bracketleft = '[',
        K_backslash = '\\',
        K_bracketright = ']',
        K_circum = '^',
        K_underscore = '_',
        K_grave = '`',
        K_a = 'a',
        K_b = 'b',
        K_c = 'c',
        K_d = 'd',
        K_e = 'e',
        K_f = 'f',
        K_g = 'g',
        K_h = 'h',
        K_i = 'i',
        K_j = 'j',
        K_k = 'k',
        K_l = 'l',
        K_m = 'm',
        K_n = 'n',
        K_o = 'o',
        K_p = 'p',
        K_q = 'q',
        K_r = 'r',
        K_s = 's',
        K_t = 't',
        K_u = 'u',
        K_v = 'v',
        K_w = 'w',
        K_x = 'x',
        K_y = 'y',
        K_z = 'z',
        K_braceleft = '{',
        K_bar = '|',
        K_braceright = '}',
        K_tilde = '~',
    }

    // #define iup_XkeyBase(_c)  ((_c) & 0x0FFFFFFF)
    // #define iup_XkeyShift(_c) ((_c) | 0x10000000)   /* Shift  */
    // #define iup_XkeyCtrl(_c)  ((_c) | 0x20000000)   /* Ctrl   */
    // #define iup_XkeyAlt(_c)   ((_c) | 0x40000000)   /* Alt    */
    // #define iup_XkeySys(_c)   ((_c) | 0x80000000)   /* Sys (Win or Apple) - notice that using "int" will display a negative value */

    int iup_XkeyCtrl(int _c) => ((_c) | 0x20000000);

    int K_cA() => iup_XkeyCtrl(K_A);
    int K_cB() => iup_XkeyCtrl(K_B);
    int K_cC() => iup_XkeyCtrl(K_C);
    int K_cD() => iup_XkeyCtrl(K_D);
    int K_cE() => iup_XkeyCtrl(K_E);
    int K_cF() => iup_XkeyCtrl(K_F);
    int K_cG() => iup_XkeyCtrl(K_G);
    int K_cH() => iup_XkeyCtrl(K_H);
    int K_cI() => iup_XkeyCtrl(K_I);
    int K_cJ() => iup_XkeyCtrl(K_J);
    int K_cK() => iup_XkeyCtrl(K_K);
    int K_cL() => iup_XkeyCtrl(K_L);
    int K_cM() => iup_XkeyCtrl(K_M);
    int K_cN() => iup_XkeyCtrl(K_N);
    int K_cO() => iup_XkeyCtrl(K_O);
    int K_cP() => iup_XkeyCtrl(K_P);
    int K_cQ() => iup_XkeyCtrl(K_Q);
    int K_cR() => iup_XkeyCtrl(K_R);
    int K_cS() => iup_XkeyCtrl(K_S);
    int K_cT() => iup_XkeyCtrl(K_T);
    int K_cU() => iup_XkeyCtrl(K_U);
    int K_cV() => iup_XkeyCtrl(K_V);
    int K_cW() => iup_XkeyCtrl(K_W);
    int K_cX() => iup_XkeyCtrl(K_X);
    int K_cY() => iup_XkeyCtrl(K_Y);
    int K_cZ() => iup_XkeyCtrl(K_Z);
    int K_c1() => iup_XkeyCtrl(K_1);
    int K_c2() => iup_XkeyCtrl(K_2);
    int K_c3() => iup_XkeyCtrl(K_3);
    int K_c4() => iup_XkeyCtrl(K_4);
    int K_c5() => iup_XkeyCtrl(K_5);
    int K_c6() => iup_XkeyCtrl(K_6);
    int K_c7() => iup_XkeyCtrl(K_7);
    int K_c8() => iup_XkeyCtrl(K_8);
    int K_c9() => iup_XkeyCtrl(K_9);
    int K_c0() => iup_XkeyCtrl(K_0);
    int K_cPlus() => iup_XkeyCtrl(K_plus);
    int K_cComma() => iup_XkeyCtrl(K_comma);
    int K_cMinus() => iup_XkeyCtrl(K_minus);
    int K_cPeriod() => iup_XkeyCtrl(K_period);
    int K_cSlash() => iup_XkeyCtrl(K_slash);
    int K_cSemicolon() => iup_XkeyCtrl(K_semicolon);
    int K_cEqual() => iup_XkeyCtrl(K_equal);
    int K_cBracketleft() => iup_XkeyCtrl(K_bracketleft);
    int K_cBracketright() => iup_XkeyCtrl(K_bracketright);
    int K_cBackslash() => iup_XkeyCtrl(K_backslash);
    int K_cAsterisk() => iup_XkeyCtrl(K_asterisk);

}
