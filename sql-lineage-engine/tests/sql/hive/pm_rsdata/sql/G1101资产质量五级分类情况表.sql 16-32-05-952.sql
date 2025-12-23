-- ============================================================
-- 文件名: G1101资产质量五级分类情况表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 290 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G1101' AS REP_NUM,
             CASE
               WHEN COLLECT_TYPE = 1 THEN
                'G11_1_2.1.1.C.2021'
               WHEN COLLECT_TYPE = 2 THEN
                'G11_1_2.1.2.C.2021'
               WHEN COLLECT_TYPE = 3 THEN
                'G11_1_2.1.3.C.2021'
               WHEN COLLECT_TYPE = 4 THEN
                'G11_1_2.1.4.C.2021'
               WHEN COLLECT_TYPE = 5 THEN
                'G11_1_2.1.5.C.2021'
               WHEN COLLECT_TYPE = 6 THEN
                'G11_1_2.2.1.C.2021'
               WHEN COLLECT_TYPE = 7 THEN
                'G11_1_2.2.2.C.2021'
               WHEN COLLECT_TYPE = 8 THEN
                'G11_1_2.2.3.C.2021'
               WHEN COLLECT_TYPE = 9 THEN
                'G11_1_2.2.4.C.2021'
               WHEN COLLECT_TYPE = 10 THEN
                'G11_1_2.2.5.C.2021'
               WHEN COLLECT_TYPE = 11 THEN
                'G11_1_2.2.6.C.2021'
               WHEN COLLECT_TYPE = 12 THEN
                'G11_1_2.2.7.C.2021'
               WHEN COLLECT_TYPE = 13 THEN
                'G11_1_2.3.1.C.2021'
               WHEN COLLECT_TYPE = 14 THEN
                'G11_1_2.3.2.C.2021'
               WHEN COLLECT_TYPE = 15 THEN
                'G11_1_2.3.3.C.2021'
               WHEN COLLECT_TYPE = 16 THEN
                'G11_1_2.3.4.C.2021'
               WHEN COLLECT_TYPE = 17 THEN
                'G11_1_2.3.5.C.2021'
               WHEN COLLECT_TYPE = 18 THEN
                'G11_1_2.3.6.C.2021'
               WHEN COLLECT_TYPE = 19 THEN
                'G11_1_2.3.7.C.2021'
               WHEN COLLECT_TYPE = 20 THEN
                'G11_1_2.3.8.C.2021'
               WHEN COLLECT_TYPE = 21 THEN
                'G11_1_2.3.9.C.2021'
               WHEN COLLECT_TYPE = 22 THEN
                'G11_1_2.3.10.C.2021'
               WHEN COLLECT_TYPE = 23 THEN
                'G11_1_2.3.11.C.2021'
               WHEN COLLECT_TYPE = 24 THEN
                'G11_1_2.3.12.C.2021'
               WHEN COLLECT_TYPE = 25 THEN
                'G11_1_2.3.13.C.2021'
               WHEN COLLECT_TYPE = 26 THEN
                'G11_1_2.3.14.C.2021'
               WHEN COLLECT_TYPE = 27 THEN
                'G11_1_2.3.15.C.2021'
               WHEN COLLECT_TYPE = 28 THEN
                'G11_1_2.3.16.C.2021'
               WHEN COLLECT_TYPE = 29 THEN
                'G11_1_2.3.17.C.2021'
               WHEN COLLECT_TYPE = 30 THEN
                'G11_1_2.3.18.C.2021'
               WHEN COLLECT_TYPE = 31 THEN
                'G11_1_2.3.19.C.2021'
               WHEN COLLECT_TYPE = 32 THEN
                'G11_1_2.3.20.C.2021'
               WHEN COLLECT_TYPE = 33 THEN
                'G11_1_2.3.21.C.2021'
               WHEN COLLECT_TYPE = 34 THEN
                'G11_1_2.3.22.C.2021'
               WHEN COLLECT_TYPE = 35 THEN
                'G11_1_2.3.23.C.2021'
               WHEN COLLECT_TYPE = 36 THEN
                'G11_1_2.3.24.C.2021'
               WHEN COLLECT_TYPE = 37 THEN
                'G11_1_2.3.25.C.2021'
               WHEN COLLECT_TYPE = 38 THEN
                'G11_1_2.3.26.C.2021'
               WHEN COLLECT_TYPE = 39 THEN
                'G11_1_2.3.27.C.2021'
               WHEN COLLECT_TYPE = 40 THEN
                'G11_1_2.3.28.C.2021'
               WHEN COLLECT_TYPE = 41 THEN
                'G11_1_2.3.29.C.2021'
               WHEN COLLECT_TYPE = 42 THEN
                'G11_1_2.3.30.C.2021'
               WHEN COLLECT_TYPE = 43 THEN
                'G11_1_2.3.31.C.2021'
               WHEN COLLECT_TYPE = 44 THEN
                'G11_1_2.4.1.C.2021'
               WHEN COLLECT_TYPE = 45 THEN
                'G11_1_2.4.2.C.2021'
               WHEN COLLECT_TYPE = 46 THEN
                'G11_1_2.4.3.C.2021'
               WHEN COLLECT_TYPE = 47 THEN
                'G11_1_2.5.1.C.2021'
               WHEN COLLECT_TYPE = 48 THEN
                'G11_1_2.5.2.C.2021'
               WHEN COLLECT_TYPE = 49 THEN
                'G11_1_2.5.3.C.2021'
               WHEN COLLECT_TYPE = 50 THEN
                'G11_1_2.5.4.C.2021'
               WHEN COLLECT_TYPE = 51 THEN
                'G11_1_2.6.1.C.2021'
               WHEN COLLECT_TYPE = 52 THEN
                'G11_1_2.6.2.C.2021'
               WHEN COLLECT_TYPE = 53 THEN
                'G11_1_2.7.1.C.2021'
               WHEN COLLECT_TYPE = 54 THEN
                'G11_1_2.7.2.C.2021'
               WHEN COLLECT_TYPE = 55 THEN
                'G11_1_2.7.3.C.2021'
               WHEN COLLECT_TYPE = 56 THEN
                'G11_1_2.7.4.C.2021'
               WHEN COLLECT_TYPE = 57 THEN
                'G11_1_2.7.5.C.2021'
               WHEN COLLECT_TYPE = 58 THEN
                'G11_1_2.7.6.C.2021'
               WHEN COLLECT_TYPE = 59 THEN
                'G11_1_2.7.7.C.2021'
               WHEN COLLECT_TYPE = 60 THEN
                'G11_1_2.7.8.C.2021'
               WHEN COLLECT_TYPE = 61 THEN
                'G11_1_2.8.1.C.2021'
               WHEN COLLECT_TYPE = 62 THEN
                'G11_1_2.8.2.C.2021'
               WHEN COLLECT_TYPE = 63 THEN
                'G11_1_2.9.1.C.2021'
               WHEN COLLECT_TYPE = 64 THEN
                'G11_1_2.9.2.C.2021'
               WHEN COLLECT_TYPE = 65 THEN
                'G11_1_2.9.3.C.2021'
               WHEN COLLECT_TYPE = 66 THEN
                'G11_1_2.10.1.C.2021'
               WHEN COLLECT_TYPE = 67 THEN
                'G11_1_2.10.2.C.2021'
               WHEN COLLECT_TYPE = 68 THEN
                'G11_1_2.10.3.C.2021'
               WHEN COLLECT_TYPE = 69 THEN
                'G11_1_2.10.4.C.2021'
               WHEN COLLECT_TYPE = 70 THEN
                'G11_1_2.11.1.C.2021'
               WHEN COLLECT_TYPE = 71 THEN
                'G11_1_2.12.1.C.2021'
               WHEN COLLECT_TYPE = 72 THEN
                'G11_1_2.12.2.C.2021'
               WHEN COLLECT_TYPE = 73 THEN
                'G11_1_2.13.1.C.2021'
               WHEN COLLECT_TYPE = 74 THEN
                'G11_1_2.13.2.C.2021'
               WHEN COLLECT_TYPE = 75 THEN
                'G11_1_2.13.3.C.2021'
               WHEN COLLECT_TYPE = 76 THEN
                'G11_1_2.14.1.C.2021'
               WHEN COLLECT_TYPE = 77 THEN
                'G11_1_2.14.2.C.2021'
               WHEN COLLECT_TYPE = 78 THEN
                'G11_1_2.14.3.C.2021'
               WHEN COLLECT_TYPE = 490 THEN
                'G11_1_2.14.4.C.2021'
             --'G11_1_2.14.4.C.2021' 过程中没有，但是取数报表有？
               WHEN COLLECT_TYPE = 79 THEN
                'G11_1_2.15.1.C.2021'
               WHEN COLLECT_TYPE = 80 THEN
                'G11_1_2.15.2.C.2021'
               WHEN COLLECT_TYPE = 81 THEN
                'G11_1_2.15.3.C.2021'
               WHEN COLLECT_TYPE = 82 THEN
                'G11_1_2.16.1.C.2021'
               WHEN COLLECT_TYPE = 83 THEN
                'G11_1_2.17.1.C.2021'
               WHEN COLLECT_TYPE = 84 THEN
                'G11_1_2.17.2.C.2021'
               WHEN COLLECT_TYPE = 85 THEN
                'G11_1_2.18.1.C.2021'
               WHEN COLLECT_TYPE = 86 THEN
                'G11_1_2.18.2.C.2021'
               WHEN COLLECT_TYPE = 87 THEN
                'G11_1_2.18.3.C.2021'
               WHEN COLLECT_TYPE = 88 THEN
                'G11_1_2.18.4.C.2021'
               WHEN COLLECT_TYPE = 89 THEN
                'G11_1_2.18.5.C.2021'
               WHEN COLLECT_TYPE = 90 THEN
                'G11_1_2.19.1.C.2021'
               WHEN COLLECT_TYPE = 91 THEN
                'G11_1_2.19.2.C.2021'
               WHEN COLLECT_TYPE = 92 THEN
                'G11_1_2.19.3.C.2021'
               WHEN COLLECT_TYPE = 93 THEN
                'G11_1_2.19.4.C.2021'
               WHEN COLLECT_TYPE = 94 THEN
                'G11_1_2.19.5.C.2021'
               WHEN COLLECT_TYPE = 95 THEN
                'G11_1_2.19.6.C.2021'
               WHEN COLLECT_TYPE = 96 THEN
                'G11_1_2.20.1.C.2021'
               WHEN COLLECT_TYPE = 97 THEN
                'G11_1_2.1.1.D.2021'
               WHEN COLLECT_TYPE = 98 THEN
                'G11_1_2.1.2.D.2021'
               WHEN COLLECT_TYPE = 99 THEN
                'G11_1_2.1.3.D.2021'
               WHEN COLLECT_TYPE = 100 THEN
                'G11_1_2.1.4.D.2021'
               WHEN COLLECT_TYPE = 101 THEN
                'G11_1_2.1.5.D.2021'
               WHEN COLLECT_TYPE = 102 THEN
                'G11_1_2.2.1.D.2021'
               WHEN COLLECT_TYPE = 103 THEN
                'G11_1_2.2.2.D.2021'
               WHEN COLLECT_TYPE = 104 THEN
                'G11_1_2.2.3.D.2021'
               WHEN COLLECT_TYPE = 105 THEN
                'G11_1_2.2.4.D.2021'
               WHEN COLLECT_TYPE = 106 THEN
                'G11_1_2.2.5.D.2021'
               WHEN COLLECT_TYPE = 107 THEN
                'G11_1_2.2.6.D.2021'
               WHEN COLLECT_TYPE = 108 THEN
                'G11_1_2.2.7.D.2021'
               WHEN COLLECT_TYPE = 109 THEN
                'G11_1_2.3.1.D.2021'
               WHEN COLLECT_TYPE = 110 THEN
                'G11_1_2.3.2.D.2021'
               WHEN COLLECT_TYPE = 111 THEN
                'G11_1_2.3.3.D.2021'
               WHEN COLLECT_TYPE = 112 THEN
                'G11_1_2.3.4.D.2021'
               WHEN COLLECT_TYPE = 113 THEN
                'G11_1_2.3.5.D.2021'
               WHEN COLLECT_TYPE = 114 THEN
                'G11_1_2.3.6.D.2021'
               WHEN COLLECT_TYPE = 115 THEN
                'G11_1_2.3.7.D.2021'
               WHEN COLLECT_TYPE = 116 THEN
                'G11_1_2.3.8.D.2021'
               WHEN COLLECT_TYPE = 117 THEN
                'G11_1_2.3.9.D.2021'
               WHEN COLLECT_TYPE = 118 THEN
                'G11_1_2.3.10.D.2021'
               WHEN COLLECT_TYPE = 119 THEN
                'G11_1_2.3.11.D.2021'
               WHEN COLLECT_TYPE = 120 THEN
                'G11_1_2.3.12.D.2021'
               WHEN COLLECT_TYPE = 121 THEN
                'G11_1_2.3.13.D.2021'
               WHEN COLLECT_TYPE = 122 THEN
                'G11_1_2.3.14.D.2021'
               WHEN COLLECT_TYPE = 123 THEN
                'G11_1_2.3.15.D.2021'
               WHEN COLLECT_TYPE = 124 THEN
                'G11_1_2.3.16.D.2021'
               WHEN COLLECT_TYPE = 125 THEN
                'G11_1_2.3.17.D.2021'
               WHEN COLLECT_TYPE = 126 THEN
                'G11_1_2.3.18.D.2021'
               WHEN COLLECT_TYPE = 127 THEN
                'G11_1_2.3.19.D.2021'
               WHEN COLLECT_TYPE = 128 THEN
                'G11_1_2.3.20.D.2021'
               WHEN COLLECT_TYPE = 129 THEN
                'G11_1_2.3.21.D.2021'
               WHEN COLLECT_TYPE = 130 THEN
                'G11_1_2.3.22.D.2021'
               WHEN COLLECT_TYPE = 131 THEN
                'G11_1_2.3.23.D.2021'
               WHEN COLLECT_TYPE = 132 THEN
                'G11_1_2.3.24.D.2021'
               WHEN COLLECT_TYPE = 133 THEN
                'G11_1_2.3.25.D.2021'
               WHEN COLLECT_TYPE = 134 THEN
                'G11_1_2.3.26.D.2021'
               WHEN COLLECT_TYPE = 135 THEN
                'G11_1_2.3.27.D.2021'
               WHEN COLLECT_TYPE = 136 THEN
                'G11_1_2.3.28.D.2021'
               WHEN COLLECT_TYPE = 137 THEN
                'G11_1_2.3.29.D.2021'
               WHEN COLLECT_TYPE = 138 THEN
                'G11_1_2.3.30.D.2021'
               WHEN COLLECT_TYPE = 139 THEN
                'G11_1_2.3.31.D.2021'
               WHEN COLLECT_TYPE = 140 THEN
                'G11_1_2.4.1.D.2021'
               WHEN COLLECT_TYPE = 141 THEN
                'G11_1_2.4.2.D.2021'
               WHEN COLLECT_TYPE = 142 THEN
                'G11_1_2.4.3.D.2021'
               WHEN COLLECT_TYPE = 143 THEN
                'G11_1_2.5.1.D.2021'
               WHEN COLLECT_TYPE = 144 THEN
                'G11_1_2.5.2.D.2021'
               WHEN COLLECT_TYPE = 145 THEN
                'G11_1_2.5.3.D.2021'
               WHEN COLLECT_TYPE = 146 THEN
                'G11_1_2.5.4.D.2021'
               WHEN COLLECT_TYPE = 147 THEN
                'G11_1_2.6.1.D.2021'
               WHEN COLLECT_TYPE = 148 THEN
                'G11_1_2.6.2.D.2021'
               WHEN COLLECT_TYPE = 149 THEN
                'G11_1_2.7.1.D.2021'
               WHEN COLLECT_TYPE = 150 THEN
                'G11_1_2.7.2.D.2021'
               WHEN COLLECT_TYPE = 151 THEN
                'G11_1_2.7.3.D.2021'
               WHEN COLLECT_TYPE = 152 THEN
                'G11_1_2.7.4.D.2021'
               WHEN COLLECT_TYPE = 153 THEN
                'G11_1_2.7.5.D.2021'
               WHEN COLLECT_TYPE = 154 THEN
                'G11_1_2.7.6.D.2021'
               WHEN COLLECT_TYPE = 155 THEN
                'G11_1_2.7.7.D.2021'
               WHEN COLLECT_TYPE = 156 THEN
                'G11_1_2.7.8.D.2021'
               WHEN COLLECT_TYPE = 157 THEN
                'G11_1_2.8.1.D.2021'
               WHEN COLLECT_TYPE = 158 THEN
                'G11_1_2.8.2.D.2021'
               WHEN COLLECT_TYPE = 159 THEN
                'G11_1_2.9.1.D.2021'
               WHEN COLLECT_TYPE = 160 THEN
                'G11_1_2.9.2.D.2021'
               WHEN COLLECT_TYPE = 161 THEN
                'G11_1_2.9.3.D.2021'
               WHEN COLLECT_TYPE = 162 THEN
                'G11_1_2.10.1.D.2021'
               WHEN COLLECT_TYPE = 163 THEN
                'G11_1_2.10.2.D.2021'
               WHEN COLLECT_TYPE = 164 THEN
                'G11_1_2.10.3.D.2021'
               WHEN COLLECT_TYPE = 165 THEN
                'G11_1_2.10.4.D.2021'
               WHEN COLLECT_TYPE = 166 THEN
                'G11_1_2.11.1.D.2021'
               WHEN COLLECT_TYPE = 167 THEN
                'G11_1_2.12.1.D.2021'
               WHEN COLLECT_TYPE = 168 THEN
                'G11_1_2.12.2.D.2021'
               WHEN COLLECT_TYPE = 169 THEN
                'G11_1_2.13.1.D.2021'
               WHEN COLLECT_TYPE = 170 THEN
                'G11_1_2.13.2.D.2021'
               WHEN COLLECT_TYPE = 171 THEN
                'G11_1_2.13.3.D.2021'
               WHEN COLLECT_TYPE = 172 THEN
                'G11_1_2.14.1.D.2021'
               WHEN COLLECT_TYPE = 173 THEN
                'G11_1_2.14.2.D.2021'
               WHEN COLLECT_TYPE = 174 THEN
                'G11_1_2.14.3.D.2021'
               WHEN COLLECT_TYPE = 491 THEN
                'G11_1_2.14.4.D.2021'
               WHEN COLLECT_TYPE = 175 THEN
                'G11_1_2.15.1.D.2021'
               WHEN COLLECT_TYPE = 176 THEN
                'G11_1_2.15.2.D.2021'
               WHEN COLLECT_TYPE = 177 THEN
                'G11_1_2.15.3.D.2021'
               WHEN COLLECT_TYPE = 178 THEN
                'G11_1_2.16.1.D.2021'
               WHEN COLLECT_TYPE = 179 THEN
                'G11_1_2.17.1.D.2021'
               WHEN COLLECT_TYPE = 180 THEN
                'G11_1_2.17.2.D.2021'
               WHEN COLLECT_TYPE = 181 THEN
                'G11_1_2.18.1.D.2021'
               WHEN COLLECT_TYPE = 182 THEN
                'G11_1_2.18.2.D.2021'
               WHEN COLLECT_TYPE = 183 THEN
                'G11_1_2.18.3.D.2021'
               WHEN COLLECT_TYPE = 184 THEN
                'G11_1_2.18.4.D.2021'
               WHEN COLLECT_TYPE = 185 THEN
                'G11_1_2.18.5.D.2021'
               WHEN COLLECT_TYPE = 186 THEN
                'G11_1_2.19.1.D.2021'
               WHEN COLLECT_TYPE = 187 THEN
                'G11_1_2.19.2.D.2021'
               WHEN COLLECT_TYPE = 188 THEN
                'G11_1_2.19.3.D.2021'
               WHEN COLLECT_TYPE = 189 THEN
                'G11_1_2.19.4.D.2021'
               WHEN COLLECT_TYPE = 190 THEN
                'G11_1_2.19.5.D.2021'
               WHEN COLLECT_TYPE = 191 THEN
                'G11_1_2.19.6.D.2021'
               WHEN COLLECT_TYPE = 192 THEN
                'G11_1_2.20.1.D.2021'
               WHEN COLLECT_TYPE = 193 THEN
                'G11_1_2.1.1.F.2021'
               WHEN COLLECT_TYPE = 194 THEN
                'G11_1_2.1.2.F.2021'
               WHEN COLLECT_TYPE = 195 THEN
                'G11_1_2.1.3.F.2021'
               WHEN COLLECT_TYPE = 196 THEN
                'G11_1_2.1.4.F.2021'
               WHEN COLLECT_TYPE = 197 THEN
                'G11_1_2.1.5.F.2021'
               WHEN COLLECT_TYPE = 198 THEN
                'G11_1_2.2.1.F.2021'
               WHEN COLLECT_TYPE = 199 THEN
                'G11_1_2.2.2.F.2021'
               WHEN COLLECT_TYPE = 200 THEN
                'G11_1_2.2.3.F.2021'
               WHEN COLLECT_TYPE = 201 THEN
                'G11_1_2.2.4.F.2021'
               WHEN COLLECT_TYPE = 202 THEN
                'G11_1_2.2.5.F.2021'
               WHEN COLLECT_TYPE = 203 THEN
                'G11_1_2.2.6.F.2021'
               WHEN COLLECT_TYPE = 204 THEN
                'G11_1_2.2.7.F.2021'
               WHEN COLLECT_TYPE = 205 THEN
                'G11_1_2.3.1.F.2021'
               WHEN COLLECT_TYPE = 206 THEN
                'G11_1_2.3.2.F.2021'
               WHEN COLLECT_TYPE = 207 THEN
                'G11_1_2.3.3.F.2021'
               WHEN COLLECT_TYPE = 208 THEN
                'G11_1_2.3.4.F.2021'
               WHEN COLLECT_TYPE = 209 THEN
                'G11_1_2.3.5.F.2021'
               WHEN COLLECT_TYPE = 210 THEN
                'G11_1_2.3.6.F.2021'
               WHEN COLLECT_TYPE = 211 THEN
                'G11_1_2.3.7.F.2021'
               WHEN COLLECT_TYPE = 212 THEN
                'G11_1_2.3.8.F.2021'
               WHEN COLLECT_TYPE = 213 THEN
                'G11_1_2.3.9.F.2021'
               WHEN COLLECT_TYPE = 214 THEN
                'G11_1_2.3.10.F.2021'
               WHEN COLLECT_TYPE = 215 THEN
                'G11_1_2.3.11.F.2021'
               WHEN COLLECT_TYPE = 216 THEN
                'G11_1_2.3.12.F.2021'
               WHEN COLLECT_TYPE = 217 THEN
                'G11_1_2.3.13.F.2021'
               WHEN COLLECT_TYPE = 218 THEN
                'G11_1_2.3.14.F.2021'
               WHEN COLLECT_TYPE = 219 THEN
                'G11_1_2.3.15.F.2021'
               WHEN COLLECT_TYPE = 220 THEN
                'G11_1_2.3.16.F.2021'
               WHEN COLLECT_TYPE = 221 THEN
                'G11_1_2.3.17.F.2021'
               WHEN COLLECT_TYPE = 222 THEN
                'G11_1_2.3.18.F.2021'
               WHEN COLLECT_TYPE = 223 THEN
                'G11_1_2.3.19.F.2021'
               WHEN COLLECT_TYPE = 224 THEN
                'G11_1_2.3.20.F.2021'
               WHEN COLLECT_TYPE = 225 THEN
                'G11_1_2.3.21.F.2021'
               WHEN COLLECT_TYPE = 226 THEN
                'G11_1_2.3.22.F.2021'
               WHEN COLLECT_TYPE = 227 THEN
                'G11_1_2.3.23.F.2021'
               WHEN COLLECT_TYPE = 228 THEN
                'G11_1_2.3.24.F.2021'
               WHEN COLLECT_TYPE = 229 THEN
                'G11_1_2.3.25.F.2021'
               WHEN COLLECT_TYPE = 230 THEN
                'G11_1_2.3.26.F.2021'
               WHEN COLLECT_TYPE = 231 THEN
                'G11_1_2.3.27.F.2021'
               WHEN COLLECT_TYPE = 232 THEN
                'G11_1_2.3.28.F.2021'
               WHEN COLLECT_TYPE = 233 THEN
                'G11_1_2.3.29.F.2021'
               WHEN COLLECT_TYPE = 234 THEN
                'G11_1_2.3.30.F.2021'
               WHEN COLLECT_TYPE = 235 THEN
                'G11_1_2.3.31.F.2021'
               WHEN COLLECT_TYPE = 236 THEN
                'G11_1_2.4.1.F.2021'
               WHEN COLLECT_TYPE = 237 THEN
                'G11_1_2.4.2.F.2021'
               WHEN COLLECT_TYPE = 238 THEN
                'G11_1_2.4.3.F.2021'
               WHEN COLLECT_TYPE = 239 THEN
                'G11_1_2.5.1.F.2021'
               WHEN COLLECT_TYPE = 240 THEN
                'G11_1_2.5.2.F.2021'
               WHEN COLLECT_TYPE = 241 THEN
                'G11_1_2.5.3.F.2021'
               WHEN COLLECT_TYPE = 242 THEN
                'G11_1_2.5.4.F.2021'
               WHEN COLLECT_TYPE = 243 THEN
                'G11_1_2.6.1.F.2021'
               WHEN COLLECT_TYPE = 244 THEN
                'G11_1_2.6.2.F.2021'
               WHEN COLLECT_TYPE = 245 THEN
                'G11_1_2.7.1.F.2021'
               WHEN COLLECT_TYPE = 246 THEN
                'G11_1_2.7.2.F.2021'
               WHEN COLLECT_TYPE = 247 THEN
                'G11_1_2.7.3.F.2021'
               WHEN COLLECT_TYPE = 248 THEN
                'G11_1_2.7.4.F.2021'
               WHEN COLLECT_TYPE = 249 THEN
                'G11_1_2.7.5.F.2021'
               WHEN COLLECT_TYPE = 250 THEN
                'G11_1_2.7.6.F.2021'
               WHEN COLLECT_TYPE = 251 THEN
                'G11_1_2.7.7.F.2021'
               WHEN COLLECT_TYPE = 252 THEN
                'G11_1_2.7.8.F.2021'
               WHEN COLLECT_TYPE = 253 THEN
                'G11_1_2.8.1.F.2021'
               WHEN COLLECT_TYPE = 254 THEN
                'G11_1_2.8.2.F.2021'
               WHEN COLLECT_TYPE = 255 THEN
                'G11_1_2.9.1.F.2021'
               WHEN COLLECT_TYPE = 256 THEN
                'G11_1_2.9.2.F.2021'
               WHEN COLLECT_TYPE = 257 THEN
                'G11_1_2.9.3.F.2021'
               WHEN COLLECT_TYPE = 258 THEN
                'G11_1_2.10.1.F.2021'
               WHEN COLLECT_TYPE = 259 THEN
                'G11_1_2.10.2.F.2021'
               WHEN COLLECT_TYPE = 260 THEN
                'G11_1_2.10.3.F.2021'
               WHEN COLLECT_TYPE = 261 THEN
                'G11_1_2.10.4.F.2021'
               WHEN COLLECT_TYPE = 262 THEN
                'G11_1_2.11.1.F.2021'
               WHEN COLLECT_TYPE = 263 THEN
                'G11_1_2.12.1.F.2021'
               WHEN COLLECT_TYPE = 264 THEN
                'G11_1_2.12.2.F.2021'
               WHEN COLLECT_TYPE = 265 THEN
                'G11_1_2.13.1.F.2021'
               WHEN COLLECT_TYPE = 266 THEN
                'G11_1_2.13.2.F.2021'
               WHEN COLLECT_TYPE = 267 THEN
                'G11_1_2.13.3.F.2021'
               WHEN COLLECT_TYPE = 268 THEN
                'G11_1_2.14.1.F.2021'
               WHEN COLLECT_TYPE = 269 THEN
                'G11_1_2.14.2.F.2021'
               WHEN COLLECT_TYPE = 270 THEN
                'G11_1_2.14.3.F.2021'
               WHEN COLLECT_TYPE = 492 THEN
                'G11_1_2.14.4.F.2021'
               WHEN COLLECT_TYPE = 271 THEN
                'G11_1_2.15.1.F.2021'
               WHEN COLLECT_TYPE = 272 THEN
                'G11_1_2.15.2.F.2021'
               WHEN COLLECT_TYPE = 273 THEN
                'G11_1_2.15.3.F.2021'
               WHEN COLLECT_TYPE = 274 THEN
                'G11_1_2.16.1.F.2021'
               WHEN COLLECT_TYPE = 275 THEN
                'G11_1_2.17.1.F.2021'
               WHEN COLLECT_TYPE = 276 THEN
                'G11_1_2.17.2.F.2021'
               WHEN COLLECT_TYPE = 277 THEN
                'G11_1_2.18.1.F.2021'
               WHEN COLLECT_TYPE = 278 THEN
                'G11_1_2.18.2.F.2021'
               WHEN COLLECT_TYPE = 279 THEN
                'G11_1_2.18.3.F.2021'
               WHEN COLLECT_TYPE = 280 THEN
                'G11_1_2.18.4.F.2021'
               WHEN COLLECT_TYPE = 281 THEN
                'G11_1_2.18.5.F.2021'
               WHEN COLLECT_TYPE = 282 THEN
                'G11_1_2.19.1.F.2021'
               WHEN COLLECT_TYPE = 283 THEN
                'G11_1_2.19.2.F.2021'
               WHEN COLLECT_TYPE = 284 THEN
                'G11_1_2.19.3.F.2021'
               WHEN COLLECT_TYPE = 285 THEN
                'G11_1_2.19.4.F.2021'
               WHEN COLLECT_TYPE = 286 THEN
                'G11_1_2.19.5.F.2021'
               WHEN COLLECT_TYPE = 287 THEN
                'G11_1_2.19.6.F.2021'
               WHEN COLLECT_TYPE = 288 THEN
                'G11_1_2.20.1.F.2021'
               WHEN COLLECT_TYPE = 289 THEN
                'G11_1_2.1.1.G.2021'
               WHEN COLLECT_TYPE = 290 THEN
                'G11_1_2.1.2.G.2021'
               WHEN COLLECT_TYPE = 291 THEN
                'G11_1_2.1.3.G.2021'
               WHEN COLLECT_TYPE = 292 THEN
                'G11_1_2.1.4.G.2021'
               WHEN COLLECT_TYPE = 293 THEN
                'G11_1_2.1.5.G.2021'
               WHEN COLLECT_TYPE = 294 THEN
                'G11_1_2.2.1.G.2021'
               WHEN COLLECT_TYPE = 295 THEN
                'G11_1_2.2.2.G.2021'
               WHEN COLLECT_TYPE = 296 THEN
                'G11_1_2.2.3.G.2021'
               WHEN COLLECT_TYPE = 297 THEN
                'G11_1_2.2.4.G.2021'
               WHEN COLLECT_TYPE = 298 THEN
                'G11_1_2.2.5.G.2021'
               WHEN COLLECT_TYPE = 299 THEN
                'G11_1_2.2.6.G.2021'
               WHEN COLLECT_TYPE = 300 THEN
                'G11_1_2.2.7.G.2021'
               WHEN COLLECT_TYPE = 301 THEN
                'G11_1_2.3.1.G.2021'
               WHEN COLLECT_TYPE = 302 THEN
                'G11_1_2.3.2.G.2021'
               WHEN COLLECT_TYPE = 303 THEN
                'G11_1_2.3.3.G.2021'
               WHEN COLLECT_TYPE = 304 THEN
                'G11_1_2.3.4.G.2021'
               WHEN COLLECT_TYPE = 305 THEN
                'G11_1_2.3.5.G.2021'
               WHEN COLLECT_TYPE = 306 THEN
                'G11_1_2.3.6.G.2021'
               WHEN COLLECT_TYPE = 307 THEN
                'G11_1_2.3.7.G.2021'
               WHEN COLLECT_TYPE = 308 THEN
                'G11_1_2.3.8.G.2021'
               WHEN COLLECT_TYPE = 309 THEN
                'G11_1_2.3.9.G.2021'
               WHEN COLLECT_TYPE = 310 THEN
                'G11_1_2.3.10.G.2021'
               WHEN COLLECT_TYPE = 311 THEN
                'G11_1_2.3.11.G.2021'
               WHEN COLLECT_TYPE = 312 THEN
                'G11_1_2.3.12.G.2021'
               WHEN COLLECT_TYPE = 313 THEN
                'G11_1_2.3.13.G.2021'
               WHEN COLLECT_TYPE = 314 THEN
                'G11_1_2.3.14.G.2021'
               WHEN COLLECT_TYPE = 315 THEN
                'G11_1_2.3.15.G.2021'
               WHEN COLLECT_TYPE = 316 THEN
                'G11_1_2.3.16.G.2021'
               WHEN COLLECT_TYPE = 317 THEN
                'G11_1_2.3.17.G.2021'
               WHEN COLLECT_TYPE = 318 THEN
                'G11_1_2.3.18.G.2021'
               WHEN COLLECT_TYPE = 319 THEN
                'G11_1_2.3.19.G.2021'
               WHEN COLLECT_TYPE = 320 THEN
                'G11_1_2.3.20.G.2021'
               WHEN COLLECT_TYPE = 321 THEN
                'G11_1_2.3.21.G.2021'
               WHEN COLLECT_TYPE = 322 THEN
                'G11_1_2.3.22.G.2021'
               WHEN COLLECT_TYPE = 323 THEN
                'G11_1_2.3.23.G.2021'
               WHEN COLLECT_TYPE = 324 THEN
                'G11_1_2.3.24.G.2021'
               WHEN COLLECT_TYPE = 325 THEN
                'G11_1_2.3.25.G.2021'
               WHEN COLLECT_TYPE = 326 THEN
                'G11_1_2.3.26.G.2021'
               WHEN COLLECT_TYPE = 327 THEN
                'G11_1_2.3.27.G.2021'
               WHEN COLLECT_TYPE = 328 THEN
                'G11_1_2.3.28.G.2021'
               WHEN COLLECT_TYPE = 329 THEN
                'G11_1_2.3.29.G.2021'
               WHEN COLLECT_TYPE = 330 THEN
                'G11_1_2.3.30.G.2021'
               WHEN COLLECT_TYPE = 331 THEN
                'G11_1_2.3.31.G.2021'
               WHEN COLLECT_TYPE = 332 THEN
                'G11_1_2.4.1.G.2021'
               WHEN COLLECT_TYPE = 333 THEN
                'G11_1_2.4.2.G.2021'
               WHEN COLLECT_TYPE = 334 THEN
                'G11_1_2.4.3.G.2021'
               WHEN COLLECT_TYPE = 335 THEN
                'G11_1_2.5.1.G.2021'
               WHEN COLLECT_TYPE = 336 THEN
                'G11_1_2.5.2.G.2021'
               WHEN COLLECT_TYPE = 337 THEN
                'G11_1_2.5.3.G.2021'
               WHEN COLLECT_TYPE = 338 THEN
                'G11_1_2.5.4.G.2021'
               WHEN COLLECT_TYPE = 339 THEN
                'G11_1_2.6.1.G.2021'
               WHEN COLLECT_TYPE = 340 THEN
                'G11_1_2.6.2.G.2021'
               WHEN COLLECT_TYPE = 341 THEN
                'G11_1_2.7.1.G.2021'
               WHEN COLLECT_TYPE = 342 THEN
                'G11_1_2.7.2.G.2021'
               WHEN COLLECT_TYPE = 343 THEN
                'G11_1_2.7.3.G.2021'
               WHEN COLLECT_TYPE = 344 THEN
                'G11_1_2.7.4.G.2021'
               WHEN COLLECT_TYPE = 345 THEN
                'G11_1_2.7.5.G.2021'
               WHEN COLLECT_TYPE = 346 THEN
                'G11_1_2.7.6.G.2021'
               WHEN COLLECT_TYPE = 347 THEN
                'G11_1_2.7.7.G.2021'
               WHEN COLLECT_TYPE = 348 THEN
                'G11_1_2.7.8.G.2021'
               WHEN COLLECT_TYPE = 349 THEN
                'G11_1_2.8.1.G.2021'
               WHEN COLLECT_TYPE = 350 THEN
                'G11_1_2.8.2.G.2021'
               WHEN COLLECT_TYPE = 351 THEN
                'G11_1_2.9.1.G.2021'
               WHEN COLLECT_TYPE = 352 THEN
                'G11_1_2.9.2.G.2021'
               WHEN COLLECT_TYPE = 353 THEN
                'G11_1_2.9.3.G.2021'
               WHEN COLLECT_TYPE = 354 THEN
                'G11_1_2.10.1.G.2021'
               WHEN COLLECT_TYPE = 355 THEN
                'G11_1_2.10.2.G.2021'
               WHEN COLLECT_TYPE = 356 THEN
                'G11_1_2.10.3.G.2021'
               WHEN COLLECT_TYPE = 357 THEN
                'G11_1_2.10.4.G.2021'
               WHEN COLLECT_TYPE = 358 THEN
                'G11_1_2.11.1.G.2021'
               WHEN COLLECT_TYPE = 359 THEN
                'G11_1_2.12.1.G.2021'
               WHEN COLLECT_TYPE = 360 THEN
                'G11_1_2.12.2.G.2021'
               WHEN COLLECT_TYPE = 361 THEN
                'G11_1_2.13.1.G.2021'
               WHEN COLLECT_TYPE = 362 THEN
                'G11_1_2.13.2.G.2021'
               WHEN COLLECT_TYPE = 363 THEN
                'G11_1_2.13.3.G.2021'
               WHEN COLLECT_TYPE = 364 THEN
                'G11_1_2.14.1.G.2021'
               WHEN COLLECT_TYPE = 365 THEN
                'G11_1_2.14.2.G.2021'
               WHEN COLLECT_TYPE = 366 THEN
                'G11_1_2.14.3.G.2021'
               WHEN COLLECT_TYPE = 493 THEN
                'G11_1_2.14.4.G.2021'
               WHEN COLLECT_TYPE = 367 THEN
                'G11_1_2.15.1.G.2021'
               WHEN COLLECT_TYPE = 368 THEN
                'G11_1_2.15.2.G.2021'
               WHEN COLLECT_TYPE = 369 THEN
                'G11_1_2.15.3.G.2021'
               WHEN COLLECT_TYPE = 370 THEN
                'G11_1_2.16.1.G.2021'
               WHEN COLLECT_TYPE = 371 THEN
                'G11_1_2.17.1.G.2021'
               WHEN COLLECT_TYPE = 372 THEN
                'G11_1_2.17.2.G.2021'
               WHEN COLLECT_TYPE = 373 THEN
                'G11_1_2.18.1.G.2021'
               WHEN COLLECT_TYPE = 374 THEN
                'G11_1_2.18.2.G.2021'
               WHEN COLLECT_TYPE = 375 THEN
                'G11_1_2.18.3.G.2021'
               WHEN COLLECT_TYPE = 376 THEN
                'G11_1_2.18.4.G.2021'
               WHEN COLLECT_TYPE = 377 THEN
                'G11_1_2.18.5.G.2021'
               WHEN COLLECT_TYPE = 378 THEN
                'G11_1_2.19.1.G.2021'
               WHEN COLLECT_TYPE = 379 THEN
                'G11_1_2.19.2.G.2021'
               WHEN COLLECT_TYPE = 380 THEN
                'G11_1_2.19.3.G.2021'
               WHEN COLLECT_TYPE = 381 THEN
                'G11_1_2.19.4.G.2021'
               WHEN COLLECT_TYPE = 382 THEN
                'G11_1_2.19.5.G.2021'
               WHEN COLLECT_TYPE = 383 THEN
                'G11_1_2.19.6.G.2021'
               WHEN COLLECT_TYPE = 384 THEN
                'G11_1_2.20.1.G.2021'
               WHEN COLLECT_TYPE = 385 THEN
                'G11_1_2.1.1.H.2021'
               WHEN COLLECT_TYPE = 386 THEN
                'G11_1_2.1.2.H.2021'
               WHEN COLLECT_TYPE = 387 THEN
                'G11_1_2.1.3.H.2021'
               WHEN COLLECT_TYPE = 388 THEN
                'G11_1_2.1.4.H.2021'
               WHEN COLLECT_TYPE = 389 THEN
                'G11_1_2.1.5.H.2021'
               WHEN COLLECT_TYPE = 390 THEN
                'G11_1_2.2.1.H.2021'
               WHEN COLLECT_TYPE = 391 THEN
                'G11_1_2.2.2.H.2021'
               WHEN COLLECT_TYPE = 392 THEN
                'G11_1_2.2.3.H.2021'
               WHEN COLLECT_TYPE = 393 THEN
                'G11_1_2.2.4.H.2021'
               WHEN COLLECT_TYPE = 394 THEN
                'G11_1_2.2.5.H.2021'
               WHEN COLLECT_TYPE = 395 THEN
                'G11_1_2.2.6.H.2021'
               WHEN COLLECT_TYPE = 396 THEN
                'G11_1_2.2.7.H.2021'
               WHEN COLLECT_TYPE = 397 THEN
                'G11_1_2.3.1.H.2021'
               WHEN COLLECT_TYPE = 398 THEN
                'G11_1_2.3.2.H.2021'
               WHEN COLLECT_TYPE = 399 THEN
                'G11_1_2.3.3.H.2021'
               WHEN COLLECT_TYPE = 400 THEN
                'G11_1_2.3.4.H.2021'
               WHEN COLLECT_TYPE = 401 THEN
                'G11_1_2.3.5.H.2021'
               WHEN COLLECT_TYPE = 402 THEN
                'G11_1_2.3.6.H.2021'
               WHEN COLLECT_TYPE = 403 THEN
                'G11_1_2.3.7.H.2021'
               WHEN COLLECT_TYPE = 404 THEN
                'G11_1_2.3.8.H.2021'
               WHEN COLLECT_TYPE = 405 THEN
                'G11_1_2.3.9.H.2021'
               WHEN COLLECT_TYPE = 406 THEN
                'G11_1_2.3.10.H.2021'
               WHEN COLLECT_TYPE = 407 THEN
                'G11_1_2.3.11.H.2021'
               WHEN COLLECT_TYPE = 408 THEN
                'G11_1_2.3.12.H.2021'
               WHEN COLLECT_TYPE = 409 THEN
                'G11_1_2.3.13.H.2021'
               WHEN COLLECT_TYPE = 410 THEN
                'G11_1_2.3.14.H.2021'
               WHEN COLLECT_TYPE = 411 THEN
                'G11_1_2.3.15.H.2021'
               WHEN COLLECT_TYPE = 412 THEN
                'G11_1_2.3.16.H.2021'
               WHEN COLLECT_TYPE = 413 THEN
                'G11_1_2.3.17.H.2021'
               WHEN COLLECT_TYPE = 414 THEN
                'G11_1_2.3.18.H.2021'
               WHEN COLLECT_TYPE = 415 THEN
                'G11_1_2.3.19.H.2021'
               WHEN COLLECT_TYPE = 416 THEN
                'G11_1_2.3.20.H.2021'
               WHEN COLLECT_TYPE = 417 THEN
                'G11_1_2.3.21.H.2021'
               WHEN COLLECT_TYPE = 418 THEN
                'G11_1_2.3.22.H.2021'
               WHEN COLLECT_TYPE = 419 THEN
                'G11_1_2.3.23.H.2021'
               WHEN COLLECT_TYPE = 420 THEN
                'G11_1_2.3.24.H.2021'
               WHEN COLLECT_TYPE = 421 THEN
                'G11_1_2.3.25.H.2021'
               WHEN COLLECT_TYPE = 422 THEN
                'G11_1_2.3.26.H.2021'
               WHEN COLLECT_TYPE = 423 THEN
                'G11_1_2.3.27.H.2021'
               WHEN COLLECT_TYPE = 424 THEN
                'G11_1_2.3.28.H.2021'
               WHEN COLLECT_TYPE = 425 THEN
                'G11_1_2.3.29.H.2021'
               WHEN COLLECT_TYPE = 426 THEN
                'G11_1_2.3.30.H.2021'
               WHEN COLLECT_TYPE = 427 THEN
                'G11_1_2.3.31.H.2021'
               WHEN COLLECT_TYPE = 428 THEN
                'G11_1_2.4.1.H.2021'
               WHEN COLLECT_TYPE = 429 THEN
                'G11_1_2.4.2.H.2021'
               WHEN COLLECT_TYPE = 430 THEN
                'G11_1_2.4.3.H.2021'
               WHEN COLLECT_TYPE = 431 THEN
                'G11_1_2.5.1.H.2021'
               WHEN COLLECT_TYPE = 432 THEN
                'G11_1_2.5.2.H.2021'
               WHEN COLLECT_TYPE = 433 THEN
                'G11_1_2.5.3.H.2021'
               WHEN COLLECT_TYPE = 434 THEN
                'G11_1_2.5.4.H.2021'
               WHEN COLLECT_TYPE = 435 THEN
                'G11_1_2.6.1.H.2021'
               WHEN COLLECT_TYPE = 436 THEN
                'G11_1_2.6.2.H.2021'
               WHEN COLLECT_TYPE = 437 THEN
                'G11_1_2.7.1.H.2021'
               WHEN COLLECT_TYPE = 438 THEN
                'G11_1_2.7.2.H.2021'
               WHEN COLLECT_TYPE = 439 THEN
                'G11_1_2.7.3.H.2021'
               WHEN COLLECT_TYPE = 440 THEN
                'G11_1_2.7.4.H.2021'
               WHEN COLLECT_TYPE = 441 THEN
                'G11_1_2.7.5.H.2021'
               WHEN COLLECT_TYPE = 442 THEN
                'G11_1_2.7.6.H.2021'
               WHEN COLLECT_TYPE = 443 THEN
                'G11_1_2.7.7.H.2021'
               WHEN COLLECT_TYPE = 444 THEN
                'G11_1_2.7.8.H.2021'
               WHEN COLLECT_TYPE = 445 THEN
                'G11_1_2.8.1.H.2021'
               WHEN COLLECT_TYPE = 446 THEN
                'G11_1_2.8.2.H.2021'
               WHEN COLLECT_TYPE = 447 THEN
                'G11_1_2.9.1.H.2021'
               WHEN COLLECT_TYPE = 448 THEN
                'G11_1_2.9.2.H.2021'
               WHEN COLLECT_TYPE = 449 THEN
                'G11_1_2.9.3.H.2021'
               WHEN COLLECT_TYPE = 450 THEN
                'G11_1_2.10.1.H.2021'
               WHEN COLLECT_TYPE = 451 THEN
                'G11_1_2.10.2.H.2021'
               WHEN COLLECT_TYPE = 452 THEN
                'G11_1_2.10.3.H.2021'
               WHEN COLLECT_TYPE = 453 THEN
                'G11_1_2.10.4.H.2021'
               WHEN COLLECT_TYPE = 454 THEN
                'G11_1_2.11.1.H.2021'
               WHEN COLLECT_TYPE = 455 THEN
                'G11_1_2.12.1.H.2021'
               WHEN COLLECT_TYPE = 456 THEN
                'G11_1_2.12.2.H.2021'
               WHEN COLLECT_TYPE = 457 THEN
                'G11_1_2.13.1.H.2021'
               WHEN COLLECT_TYPE = 458 THEN
                'G11_1_2.13.2.H.2021'
               WHEN COLLECT_TYPE = 459 THEN
                'G11_1_2.13.3.H.2021'
               WHEN COLLECT_TYPE = 460 THEN
                'G11_1_2.14.1.H.2021'
               WHEN COLLECT_TYPE = 461 THEN
                'G11_1_2.14.2.H.2021'
               WHEN COLLECT_TYPE = 462 THEN
                'G11_1_2.14.3.H.2021'
               WHEN COLLECT_TYPE = 494 THEN
                'G11_1_2.14.4.H.2021'
               WHEN COLLECT_TYPE = 463 THEN
                'G11_1_2.15.1.H.2021'
               WHEN COLLECT_TYPE = 464 THEN
                'G11_1_2.15.2.H.2021'
               WHEN COLLECT_TYPE = 465 THEN
                'G11_1_2.15.3.H.2021'
               WHEN COLLECT_TYPE = 466 THEN
                'G11_1_2.16.1.H.2021'
               WHEN COLLECT_TYPE = 467 THEN
                'G11_1_2.17.1.H.2021'
               WHEN COLLECT_TYPE = 468 THEN
                'G11_1_2.17.2.H.2021'
               WHEN COLLECT_TYPE = 469 THEN
                'G11_1_2.18.1.H.2021'
               WHEN COLLECT_TYPE = 470 THEN
                'G11_1_2.18.2.H.2021'
               WHEN COLLECT_TYPE = 471 THEN
                'G11_1_2.18.3.H.2021'
               WHEN COLLECT_TYPE = 472 THEN
                'G11_1_2.18.4.H.2021'
               WHEN COLLECT_TYPE = 473 THEN
                'G11_1_2.18.5.H.2021'
               WHEN COLLECT_TYPE = 474 THEN
                'G11_1_2.19.1.H.2021'
               WHEN COLLECT_TYPE = 475 THEN
                'G11_1_2.19.2.H.2021'
               WHEN COLLECT_TYPE = 476 THEN
                'G11_1_2.19.3.H.2021'
               WHEN COLLECT_TYPE = 477 THEN
                'G11_1_2.19.4.H.2021'
               WHEN COLLECT_TYPE = 478 THEN
                'G11_1_2.19.5.H.2021'
               WHEN COLLECT_TYPE = 479 THEN
                'G11_1_2.19.6.H.2021'
               WHEN COLLECT_TYPE = 480 THEN
                'G11_1_2.20.1.H.2021'
             END AS ITEM_NUM,
             SUM(COLLECT_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_PUB_DATA_COLLECT_G1101
       WHERE COLLECT_TYPE IS NOT NULL
       GROUP BY ORG_NUM,
                CASE
                  WHEN COLLECT_TYPE = 1 THEN
                   'G11_1_2.1.1.C.2021'
                  WHEN COLLECT_TYPE = 2 THEN
                   'G11_1_2.1.2.C.2021'
                  WHEN COLLECT_TYPE = 3 THEN
                   'G11_1_2.1.3.C.2021'
                  WHEN COLLECT_TYPE = 4 THEN
                   'G11_1_2.1.4.C.2021'
                  WHEN COLLECT_TYPE = 5 THEN
                   'G11_1_2.1.5.C.2021'
                  WHEN COLLECT_TYPE = 6 THEN
                   'G11_1_2.2.1.C.2021'
                  WHEN COLLECT_TYPE = 7 THEN
                   'G11_1_2.2.2.C.2021'
                  WHEN COLLECT_TYPE = 8 THEN
                   'G11_1_2.2.3.C.2021'
                  WHEN COLLECT_TYPE = 9 THEN
                   'G11_1_2.2.4.C.2021'
                  WHEN COLLECT_TYPE = 10 THEN
                   'G11_1_2.2.5.C.2021'
                  WHEN COLLECT_TYPE = 11 THEN
                   'G11_1_2.2.6.C.2021'
                  WHEN COLLECT_TYPE = 12 THEN
                   'G11_1_2.2.7.C.2021'
                  WHEN COLLECT_TYPE = 13 THEN
                   'G11_1_2.3.1.C.2021'
                  WHEN COLLECT_TYPE = 14 THEN
                   'G11_1_2.3.2.C.2021'
                  WHEN COLLECT_TYPE = 15 THEN
                   'G11_1_2.3.3.C.2021'
                  WHEN COLLECT_TYPE = 16 THEN
                   'G11_1_2.3.4.C.2021'
                  WHEN COLLECT_TYPE = 17 THEN
                   'G11_1_2.3.5.C.2021'
                  WHEN COLLECT_TYPE = 18 THEN
                   'G11_1_2.3.6.C.2021'
                  WHEN COLLECT_TYPE = 19 THEN
                   'G11_1_2.3.7.C.2021'
                  WHEN COLLECT_TYPE = 20 THEN
                   'G11_1_2.3.8.C.2021'
                  WHEN COLLECT_TYPE = 21 THEN
                   'G11_1_2.3.9.C.2021'
                  WHEN COLLECT_TYPE = 22 THEN
                   'G11_1_2.3.10.C.2021'
                  WHEN COLLECT_TYPE = 23 THEN
                   'G11_1_2.3.11.C.2021'
                  WHEN COLLECT_TYPE = 24 THEN
                   'G11_1_2.3.12.C.2021'
                  WHEN COLLECT_TYPE = 25 THEN
                   'G11_1_2.3.13.C.2021'
                  WHEN COLLECT_TYPE = 26 THEN
                   'G11_1_2.3.14.C.2021'
                  WHEN COLLECT_TYPE = 27 THEN
                   'G11_1_2.3.15.C.2021'
                  WHEN COLLECT_TYPE = 28 THEN
                   'G11_1_2.3.16.C.2021'
                  WHEN COLLECT_TYPE = 29 THEN
                   'G11_1_2.3.17.C.2021'
                  WHEN COLLECT_TYPE = 30 THEN
                   'G11_1_2.3.18.C.2021'
                  WHEN COLLECT_TYPE = 31 THEN
                   'G11_1_2.3.19.C.2021'
                  WHEN COLLECT_TYPE = 32 THEN
                   'G11_1_2.3.20.C.2021'
                  WHEN COLLECT_TYPE = 33 THEN
                   'G11_1_2.3.21.C.2021'
                  WHEN COLLECT_TYPE = 34 THEN
                   'G11_1_2.3.22.C.2021'
                  WHEN COLLECT_TYPE = 35 THEN
                   'G11_1_2.3.23.C.2021'
                  WHEN COLLECT_TYPE = 36 THEN
                   'G11_1_2.3.24.C.2021'
                  WHEN COLLECT_TYPE = 37 THEN
                   'G11_1_2.3.25.C.2021'
                  WHEN COLLECT_TYPE = 38 THEN
                   'G11_1_2.3.26.C.2021'
                  WHEN COLLECT_TYPE = 39 THEN
                   'G11_1_2.3.27.C.2021'
                  WHEN COLLECT_TYPE = 40 THEN
                   'G11_1_2.3.28.C.2021'
                  WHEN COLLECT_TYPE = 41 THEN
                   'G11_1_2.3.29.C.2021'
                  WHEN COLLECT_TYPE = 42 THEN
                   'G11_1_2.3.30.C.2021'
                  WHEN COLLECT_TYPE = 43 THEN
                   'G11_1_2.3.31.C.2021'
                  WHEN COLLECT_TYPE = 44 THEN
                   'G11_1_2.4.1.C.2021'
                  WHEN COLLECT_TYPE = 45 THEN
                   'G11_1_2.4.2.C.2021'
                  WHEN COLLECT_TYPE = 46 THEN
                   'G11_1_2.4.3.C.2021'
                  WHEN COLLECT_TYPE = 47 THEN
                   'G11_1_2.5.1.C.2021'
                  WHEN COLLECT_TYPE = 48 THEN
                   'G11_1_2.5.2.C.2021'
                  WHEN COLLECT_TYPE = 49 THEN
                   'G11_1_2.5.3.C.2021'
                  WHEN COLLECT_TYPE = 50 THEN
                   'G11_1_2.5.4.C.2021'
                  WHEN COLLECT_TYPE = 51 THEN
                   'G11_1_2.6.1.C.2021'
                  WHEN COLLECT_TYPE = 52 THEN
                   'G11_1_2.6.2.C.2021'
                  WHEN COLLECT_TYPE = 53 THEN
                   'G11_1_2.7.1.C.2021'
                  WHEN COLLECT_TYPE = 54 THEN
                   'G11_1_2.7.2.C.2021'
                  WHEN COLLECT_TYPE = 55 THEN
                   'G11_1_2.7.3.C.2021'
                  WHEN COLLECT_TYPE = 56 THEN
                   'G11_1_2.7.4.C.2021'
                  WHEN COLLECT_TYPE = 57 THEN
                   'G11_1_2.7.5.C.2021'
                  WHEN COLLECT_TYPE = 58 THEN
                   'G11_1_2.7.6.C.2021'
                  WHEN COLLECT_TYPE = 59 THEN
                   'G11_1_2.7.7.C.2021'
                  WHEN COLLECT_TYPE = 60 THEN
                   'G11_1_2.7.8.C.2021'
                  WHEN COLLECT_TYPE = 61 THEN
                   'G11_1_2.8.1.C.2021'
                  WHEN COLLECT_TYPE = 62 THEN
                   'G11_1_2.8.2.C.2021'
                  WHEN COLLECT_TYPE = 63 THEN
                   'G11_1_2.9.1.C.2021'
                  WHEN COLLECT_TYPE = 64 THEN
                   'G11_1_2.9.2.C.2021'
                  WHEN COLLECT_TYPE = 65 THEN
                   'G11_1_2.9.3.C.2021'
                  WHEN COLLECT_TYPE = 66 THEN
                   'G11_1_2.10.1.C.2021'
                  WHEN COLLECT_TYPE = 67 THEN
                   'G11_1_2.10.2.C.2021'
                  WHEN COLLECT_TYPE = 68 THEN
                   'G11_1_2.10.3.C.2021'
                  WHEN COLLECT_TYPE = 69 THEN
                   'G11_1_2.10.4.C.2021'
                  WHEN COLLECT_TYPE = 70 THEN
                   'G11_1_2.11.1.C.2021'
                  WHEN COLLECT_TYPE = 71 THEN
                   'G11_1_2.12.1.C.2021'
                  WHEN COLLECT_TYPE = 72 THEN
                   'G11_1_2.12.2.C.2021'
                  WHEN COLLECT_TYPE = 73 THEN
                   'G11_1_2.13.1.C.2021'
                  WHEN COLLECT_TYPE = 74 THEN
                   'G11_1_2.13.2.C.2021'
                  WHEN COLLECT_TYPE = 75 THEN
                   'G11_1_2.13.3.C.2021'
                  WHEN COLLECT_TYPE = 76 THEN
                   'G11_1_2.14.1.C.2021'
                  WHEN COLLECT_TYPE = 77 THEN
                   'G11_1_2.14.2.C.2021'
                  WHEN COLLECT_TYPE = 78 THEN
                   'G11_1_2.14.3.C.2021'
                  WHEN COLLECT_TYPE = 490 THEN
                   'G11_1_2.14.4.C.2021'
                --'G11_1_2.14.4.C.2021' 过程中没有，报表设计器没有，但是取数报表有，手工填报还是重新取数？
                  WHEN COLLECT_TYPE = 79 THEN
                   'G11_1_2.15.1.C.2021'
                  WHEN COLLECT_TYPE = 80 THEN
                   'G11_1_2.15.2.C.2021'
                  WHEN COLLECT_TYPE = 81 THEN
                   'G11_1_2.15.3.C.2021'
                  WHEN COLLECT_TYPE = 82 THEN
                   'G11_1_2.16.1.C.2021'
                  WHEN COLLECT_TYPE = 83 THEN
                   'G11_1_2.17.1.C.2021'
                  WHEN COLLECT_TYPE = 84 THEN
                   'G11_1_2.17.2.C.2021'
                  WHEN COLLECT_TYPE = 85 THEN
                   'G11_1_2.18.1.C.2021'
                  WHEN COLLECT_TYPE = 86 THEN
                   'G11_1_2.18.2.C.2021'
                  WHEN COLLECT_TYPE = 87 THEN
                   'G11_1_2.18.3.C.2021'
                  WHEN COLLECT_TYPE = 88 THEN
                   'G11_1_2.18.4.C.2021'
                  WHEN COLLECT_TYPE = 89 THEN
                   'G11_1_2.18.5.C.2021'
                  WHEN COLLECT_TYPE = 90 THEN
                   'G11_1_2.19.1.C.2021'
                  WHEN COLLECT_TYPE = 91 THEN
                   'G11_1_2.19.2.C.2021'
                  WHEN COLLECT_TYPE = 92 THEN
                   'G11_1_2.19.3.C.2021'
                  WHEN COLLECT_TYPE = 93 THEN
                   'G11_1_2.19.4.C.2021'
                  WHEN COLLECT_TYPE = 94 THEN
                   'G11_1_2.19.5.C.2021'
                  WHEN COLLECT_TYPE = 95 THEN
                   'G11_1_2.19.6.C.2021'
                  WHEN COLLECT_TYPE = 96 THEN
                   'G11_1_2.20.1.C.2021'
                  WHEN COLLECT_TYPE = 97 THEN
                   'G11_1_2.1.1.D.2021'
                  WHEN COLLECT_TYPE = 98 THEN
                   'G11_1_2.1.2.D.2021'
                  WHEN COLLECT_TYPE = 99 THEN
                   'G11_1_2.1.3.D.2021'
                  WHEN COLLECT_TYPE = 100 THEN
                   'G11_1_2.1.4.D.2021'
                  WHEN COLLECT_TYPE = 101 THEN
                   'G11_1_2.1.5.D.2021'
                  WHEN COLLECT_TYPE = 102 THEN
                   'G11_1_2.2.1.D.2021'
                  WHEN COLLECT_TYPE = 103 THEN
                   'G11_1_2.2.2.D.2021'
                  WHEN COLLECT_TYPE = 104 THEN
                   'G11_1_2.2.3.D.2021'
                  WHEN COLLECT_TYPE = 105 THEN
                   'G11_1_2.2.4.D.2021'
                  WHEN COLLECT_TYPE = 106 THEN
                   'G11_1_2.2.5.D.2021'
                  WHEN COLLECT_TYPE = 107 THEN
                   'G11_1_2.2.6.D.2021'
                  WHEN COLLECT_TYPE = 108 THEN
                   'G11_1_2.2.7.D.2021'
                  WHEN COLLECT_TYPE = 109 THEN
                   'G11_1_2.3.1.D.2021'
                  WHEN COLLECT_TYPE = 110 THEN
                   'G11_1_2.3.2.D.2021'
                  WHEN COLLECT_TYPE = 111 THEN
                   'G11_1_2.3.3.D.2021'
                  WHEN COLLECT_TYPE = 112 THEN
                   'G11_1_2.3.4.D.2021'
                  WHEN COLLECT_TYPE = 113 THEN
                   'G11_1_2.3.5.D.2021'
                  WHEN COLLECT_TYPE = 114 THEN
                   'G11_1_2.3.6.D.2021'
                  WHEN COLLECT_TYPE = 115 THEN
                   'G11_1_2.3.7.D.2021'
                  WHEN COLLECT_TYPE = 116 THEN
                   'G11_1_2.3.8.D.2021'
                  WHEN COLLECT_TYPE = 117 THEN
                   'G11_1_2.3.9.D.2021'
                  WHEN COLLECT_TYPE = 118 THEN
                   'G11_1_2.3.10.D.2021'
                  WHEN COLLECT_TYPE = 119 THEN
                   'G11_1_2.3.11.D.2021'
                  WHEN COLLECT_TYPE = 120 THEN
                   'G11_1_2.3.12.D.2021'
                  WHEN COLLECT_TYPE = 121 THEN
                   'G11_1_2.3.13.D.2021'
                  WHEN COLLECT_TYPE = 122 THEN
                   'G11_1_2.3.14.D.2021'
                  WHEN COLLECT_TYPE = 123 THEN
                   'G11_1_2.3.15.D.2021'
                  WHEN COLLECT_TYPE = 124 THEN
                   'G11_1_2.3.16.D.2021'
                  WHEN COLLECT_TYPE = 125 THEN
                   'G11_1_2.3.17.D.2021'
                  WHEN COLLECT_TYPE = 126 THEN
                   'G11_1_2.3.18.D.2021'
                  WHEN COLLECT_TYPE = 127 THEN
                   'G11_1_2.3.19.D.2021'
                  WHEN COLLECT_TYPE = 128 THEN
                   'G11_1_2.3.20.D.2021'
                  WHEN COLLECT_TYPE = 129 THEN
                   'G11_1_2.3.21.D.2021'
                  WHEN COLLECT_TYPE = 130 THEN
                   'G11_1_2.3.22.D.2021'
                  WHEN COLLECT_TYPE = 131 THEN
                   'G11_1_2.3.23.D.2021'
                  WHEN COLLECT_TYPE = 132 THEN
                   'G11_1_2.3.24.D.2021'
                  WHEN COLLECT_TYPE = 133 THEN
                   'G11_1_2.3.25.D.2021'
                  WHEN COLLECT_TYPE = 134 THEN
                   'G11_1_2.3.26.D.2021'
                  WHEN COLLECT_TYPE = 135 THEN
                   'G11_1_2.3.27.D.2021'
                  WHEN COLLECT_TYPE = 136 THEN
                   'G11_1_2.3.28.D.2021'
                  WHEN COLLECT_TYPE = 137 THEN
                   'G11_1_2.3.29.D.2021'
                  WHEN COLLECT_TYPE = 138 THEN
                   'G11_1_2.3.30.D.2021'
                  WHEN COLLECT_TYPE = 139 THEN
                   'G11_1_2.3.31.D.2021'
                  WHEN COLLECT_TYPE = 140 THEN
                   'G11_1_2.4.1.D.2021'
                  WHEN COLLECT_TYPE = 141 THEN
                   'G11_1_2.4.2.D.2021'
                  WHEN COLLECT_TYPE = 142 THEN
                   'G11_1_2.4.3.D.2021'
                  WHEN COLLECT_TYPE = 143 THEN
                   'G11_1_2.5.1.D.2021'
                  WHEN COLLECT_TYPE = 144 THEN
                   'G11_1_2.5.2.D.2021'
                  WHEN COLLECT_TYPE = 145 THEN
                   'G11_1_2.5.3.D.2021'
                  WHEN COLLECT_TYPE = 146 THEN
                   'G11_1_2.5.4.D.2021'
                  WHEN COLLECT_TYPE = 147 THEN
                   'G11_1_2.6.1.D.2021'
                  WHEN COLLECT_TYPE = 148 THEN
                   'G11_1_2.6.2.D.2021'
                  WHEN COLLECT_TYPE = 149 THEN
                   'G11_1_2.7.1.D.2021'
                  WHEN COLLECT_TYPE = 150 THEN
                   'G11_1_2.7.2.D.2021'
                  WHEN COLLECT_TYPE = 151 THEN
                   'G11_1_2.7.3.D.2021'
                  WHEN COLLECT_TYPE = 152 THEN
                   'G11_1_2.7.4.D.2021'
                  WHEN COLLECT_TYPE = 153 THEN
                   'G11_1_2.7.5.D.2021'
                  WHEN COLLECT_TYPE = 154 THEN
                   'G11_1_2.7.6.D.2021'
                  WHEN COLLECT_TYPE = 155 THEN
                   'G11_1_2.7.7.D.2021'
                  WHEN COLLECT_TYPE = 156 THEN
                   'G11_1_2.7.8.D.2021'
                  WHEN COLLECT_TYPE = 157 THEN
                   'G11_1_2.8.1.D.2021'
                  WHEN COLLECT_TYPE = 158 THEN
                   'G11_1_2.8.2.D.2021'
                  WHEN COLLECT_TYPE = 159 THEN
                   'G11_1_2.9.1.D.2021'
                  WHEN COLLECT_TYPE = 160 THEN
                   'G11_1_2.9.2.D.2021'
                  WHEN COLLECT_TYPE = 161 THEN
                   'G11_1_2.9.3.D.2021'
                  WHEN COLLECT_TYPE = 162 THEN
                   'G11_1_2.10.1.D.2021'
                  WHEN COLLECT_TYPE = 163 THEN
                   'G11_1_2.10.2.D.2021'
                  WHEN COLLECT_TYPE = 164 THEN
                   'G11_1_2.10.3.D.2021'
                  WHEN COLLECT_TYPE = 165 THEN
                   'G11_1_2.10.4.D.2021'
                  WHEN COLLECT_TYPE = 166 THEN
                   'G11_1_2.11.1.D.2021'
                  WHEN COLLECT_TYPE = 167 THEN
                   'G11_1_2.12.1.D.2021'
                  WHEN COLLECT_TYPE = 168 THEN
                   'G11_1_2.12.2.D.2021'
                  WHEN COLLECT_TYPE = 169 THEN
                   'G11_1_2.13.1.D.2021'
                  WHEN COLLECT_TYPE = 170 THEN
                   'G11_1_2.13.2.D.2021'
                  WHEN COLLECT_TYPE = 171 THEN
                   'G11_1_2.13.3.D.2021'
                  WHEN COLLECT_TYPE = 172 THEN
                   'G11_1_2.14.1.D.2021'
                  WHEN COLLECT_TYPE = 173 THEN
                   'G11_1_2.14.2.D.2021'
                  WHEN COLLECT_TYPE = 174 THEN
                   'G11_1_2.14.3.D.2021'
                  WHEN COLLECT_TYPE = 491 THEN
                   'G11_1_2.14.4.D.2021'
                  WHEN COLLECT_TYPE = 175 THEN
                   'G11_1_2.15.1.D.2021'
                  WHEN COLLECT_TYPE = 176 THEN
                   'G11_1_2.15.2.D.2021'
                  WHEN COLLECT_TYPE = 177 THEN
                   'G11_1_2.15.3.D.2021'
                  WHEN COLLECT_TYPE = 178 THEN
                   'G11_1_2.16.1.D.2021'
                  WHEN COLLECT_TYPE = 179 THEN
                   'G11_1_2.17.1.D.2021'
                  WHEN COLLECT_TYPE = 180 THEN
                   'G11_1_2.17.2.D.2021'
                  WHEN COLLECT_TYPE = 181 THEN
                   'G11_1_2.18.1.D.2021'
                  WHEN COLLECT_TYPE = 182 THEN
                   'G11_1_2.18.2.D.2021'
                  WHEN COLLECT_TYPE = 183 THEN
                   'G11_1_2.18.3.D.2021'
                  WHEN COLLECT_TYPE = 184 THEN
                   'G11_1_2.18.4.D.2021'
                  WHEN COLLECT_TYPE = 185 THEN
                   'G11_1_2.18.5.D.2021'
                  WHEN COLLECT_TYPE = 186 THEN
                   'G11_1_2.19.1.D.2021'
                  WHEN COLLECT_TYPE = 187 THEN
                   'G11_1_2.19.2.D.2021'
                  WHEN COLLECT_TYPE = 188 THEN
                   'G11_1_2.19.3.D.2021'
                  WHEN COLLECT_TYPE = 189 THEN
                   'G11_1_2.19.4.D.2021'
                  WHEN COLLECT_TYPE = 190 THEN
                   'G11_1_2.19.5.D.2021'
                  WHEN COLLECT_TYPE = 191 THEN
                   'G11_1_2.19.6.D.2021'
                  WHEN COLLECT_TYPE = 192 THEN
                   'G11_1_2.20.1.D.2021'
                  WHEN COLLECT_TYPE = 193 THEN
                   'G11_1_2.1.1.F.2021'
                  WHEN COLLECT_TYPE = 194 THEN
                   'G11_1_2.1.2.F.2021'
                  WHEN COLLECT_TYPE = 195 THEN
                   'G11_1_2.1.3.F.2021'
                  WHEN COLLECT_TYPE = 196 THEN
                   'G11_1_2.1.4.F.2021'
                  WHEN COLLECT_TYPE = 197 THEN
                   'G11_1_2.1.5.F.2021'
                  WHEN COLLECT_TYPE = 198 THEN
                   'G11_1_2.2.1.F.2021'
                  WHEN COLLECT_TYPE = 199 THEN
                   'G11_1_2.2.2.F.2021'
                  WHEN COLLECT_TYPE = 200 THEN
                   'G11_1_2.2.3.F.2021'
                  WHEN COLLECT_TYPE = 201 THEN
                   'G11_1_2.2.4.F.2021'
                  WHEN COLLECT_TYPE = 202 THEN
                   'G11_1_2.2.5.F.2021'
                  WHEN COLLECT_TYPE = 203 THEN
                   'G11_1_2.2.6.F.2021'
                  WHEN COLLECT_TYPE = 204 THEN
                   'G11_1_2.2.7.F.2021'
                  WHEN COLLECT_TYPE = 205 THEN
                   'G11_1_2.3.1.F.2021'
                  WHEN COLLECT_TYPE = 206 THEN
                   'G11_1_2.3.2.F.2021'
                  WHEN COLLECT_TYPE = 207 THEN
                   'G11_1_2.3.3.F.2021'
                  WHEN COLLECT_TYPE = 208 THEN
                   'G11_1_2.3.4.F.2021'
                  WHEN COLLECT_TYPE = 209 THEN
                   'G11_1_2.3.5.F.2021'
                  WHEN COLLECT_TYPE = 210 THEN
                   'G11_1_2.3.6.F.2021'
                  WHEN COLLECT_TYPE = 211 THEN
                   'G11_1_2.3.7.F.2021'
                  WHEN COLLECT_TYPE = 212 THEN
                   'G11_1_2.3.8.F.2021'
                  WHEN COLLECT_TYPE = 213 THEN
                   'G11_1_2.3.9.F.2021'
                  WHEN COLLECT_TYPE = 214 THEN
                   'G11_1_2.3.10.F.2021'
                  WHEN COLLECT_TYPE = 215 THEN
                   'G11_1_2.3.11.F.2021'
                  WHEN COLLECT_TYPE = 216 THEN
                   'G11_1_2.3.12.F.2021'
                  WHEN COLLECT_TYPE = 217 THEN
                   'G11_1_2.3.13.F.2021'
                  WHEN COLLECT_TYPE = 218 THEN
                   'G11_1_2.3.14.F.2021'
                  WHEN COLLECT_TYPE = 219 THEN
                   'G11_1_2.3.15.F.2021'
                  WHEN COLLECT_TYPE = 220 THEN
                   'G11_1_2.3.16.F.2021'
                  WHEN COLLECT_TYPE = 221 THEN
                   'G11_1_2.3.17.F.2021'
                  WHEN COLLECT_TYPE = 222 THEN
                   'G11_1_2.3.18.F.2021'
                  WHEN COLLECT_TYPE = 223 THEN
                   'G11_1_2.3.19.F.2021'
                  WHEN COLLECT_TYPE = 224 THEN
                   'G11_1_2.3.20.F.2021'
                  WHEN COLLECT_TYPE = 225 THEN
                   'G11_1_2.3.21.F.2021'
                  WHEN COLLECT_TYPE = 226 THEN
                   'G11_1_2.3.22.F.2021'
                  WHEN COLLECT_TYPE = 227 THEN
                   'G11_1_2.3.23.F.2021'
                  WHEN COLLECT_TYPE = 228 THEN
                   'G11_1_2.3.24.F.2021'
                  WHEN COLLECT_TYPE = 229 THEN
                   'G11_1_2.3.25.F.2021'
                  WHEN COLLECT_TYPE = 230 THEN
                   'G11_1_2.3.26.F.2021'
                  WHEN COLLECT_TYPE = 231 THEN
                   'G11_1_2.3.27.F.2021'
                  WHEN COLLECT_TYPE = 232 THEN
                   'G11_1_2.3.28.F.2021'
                  WHEN COLLECT_TYPE = 233 THEN
                   'G11_1_2.3.29.F.2021'
                  WHEN COLLECT_TYPE = 234 THEN
                   'G11_1_2.3.30.F.2021'
                  WHEN COLLECT_TYPE = 235 THEN
                   'G11_1_2.3.31.F.2021'
                  WHEN COLLECT_TYPE = 236 THEN
                   'G11_1_2.4.1.F.2021'
                  WHEN COLLECT_TYPE = 237 THEN
                   'G11_1_2.4.2.F.2021'
                  WHEN COLLECT_TYPE = 238 THEN
                   'G11_1_2.4.3.F.2021'
                  WHEN COLLECT_TYPE = 239 THEN
                   'G11_1_2.5.1.F.2021'
                  WHEN COLLECT_TYPE = 240 THEN
                   'G11_1_2.5.2.F.2021'
                  WHEN COLLECT_TYPE = 241 THEN
                   'G11_1_2.5.3.F.2021'
                  WHEN COLLECT_TYPE = 242 THEN
                   'G11_1_2.5.4.F.2021'
                  WHEN COLLECT_TYPE = 243 THEN
                   'G11_1_2.6.1.F.2021'
                  WHEN COLLECT_TYPE = 244 THEN
                   'G11_1_2.6.2.F.2021'
                  WHEN COLLECT_TYPE = 245 THEN
                   'G11_1_2.7.1.F.2021'
                  WHEN COLLECT_TYPE = 246 THEN
                   'G11_1_2.7.2.F.2021'
                  WHEN COLLECT_TYPE = 247 THEN
                   'G11_1_2.7.3.F.2021'
                  WHEN COLLECT_TYPE = 248 THEN
                   'G11_1_2.7.4.F.2021'
                  WHEN COLLECT_TYPE = 249 THEN
                   'G11_1_2.7.5.F.2021'
                  WHEN COLLECT_TYPE = 250 THEN
                   'G11_1_2.7.6.F.2021'
                  WHEN COLLECT_TYPE = 251 THEN
                   'G11_1_2.7.7.F.2021'
                  WHEN COLLECT_TYPE = 252 THEN
                   'G11_1_2.7.8.F.2021'
                  WHEN COLLECT_TYPE = 253 THEN
                   'G11_1_2.8.1.F.2021'
                  WHEN COLLECT_TYPE = 254 THEN
                   'G11_1_2.8.2.F.2021'
                  WHEN COLLECT_TYPE = 255 THEN
                   'G11_1_2.9.1.F.2021'
                  WHEN COLLECT_TYPE = 256 THEN
                   'G11_1_2.9.2.F.2021'
                  WHEN COLLECT_TYPE = 257 THEN
                   'G11_1_2.9.3.F.2021'
                  WHEN COLLECT_TYPE = 258 THEN
                   'G11_1_2.10.1.F.2021'
                  WHEN COLLECT_TYPE = 259 THEN
                   'G11_1_2.10.2.F.2021'
                  WHEN COLLECT_TYPE = 260 THEN
                   'G11_1_2.10.3.F.2021'
                  WHEN COLLECT_TYPE = 261 THEN
                   'G11_1_2.10.4.F.2021'
                  WHEN COLLECT_TYPE = 262 THEN
                   'G11_1_2.11.1.F.2021'
                  WHEN COLLECT_TYPE = 263 THEN
                   'G11_1_2.12.1.F.2021'
                  WHEN COLLECT_TYPE = 264 THEN
                   'G11_1_2.12.2.F.2021'
                  WHEN COLLECT_TYPE = 265 THEN
                   'G11_1_2.13.1.F.2021'
                  WHEN COLLECT_TYPE = 266 THEN
                   'G11_1_2.13.2.F.2021'
                  WHEN COLLECT_TYPE = 267 THEN
                   'G11_1_2.13.3.F.2021'
                  WHEN COLLECT_TYPE = 268 THEN
                   'G11_1_2.14.1.F.2021'
                  WHEN COLLECT_TYPE = 269 THEN
                   'G11_1_2.14.2.F.2021'
                  WHEN COLLECT_TYPE = 270 THEN
                   'G11_1_2.14.3.F.2021'
                  WHEN COLLECT_TYPE = 492 THEN
                   'G11_1_2.14.4.F.2021'
                  WHEN COLLECT_TYPE = 271 THEN
                   'G11_1_2.15.1.F.2021'
                  WHEN COLLECT_TYPE = 272 THEN
                   'G11_1_2.15.2.F.2021'
                  WHEN COLLECT_TYPE = 273 THEN
                   'G11_1_2.15.3.F.2021'
                  WHEN COLLECT_TYPE = 274 THEN
                   'G11_1_2.16.1.F.2021'
                  WHEN COLLECT_TYPE = 275 THEN
                   'G11_1_2.17.1.F.2021'
                  WHEN COLLECT_TYPE = 276 THEN
                   'G11_1_2.17.2.F.2021'
                  WHEN COLLECT_TYPE = 277 THEN
                   'G11_1_2.18.1.F.2021'
                  WHEN COLLECT_TYPE = 278 THEN
                   'G11_1_2.18.2.F.2021'
                  WHEN COLLECT_TYPE = 279 THEN
                   'G11_1_2.18.3.F.2021'
                  WHEN COLLECT_TYPE = 280 THEN
                   'G11_1_2.18.4.F.2021'
                  WHEN COLLECT_TYPE = 281 THEN
                   'G11_1_2.18.5.F.2021'
                  WHEN COLLECT_TYPE = 282 THEN
                   'G11_1_2.19.1.F.2021'
                  WHEN COLLECT_TYPE = 283 THEN
                   'G11_1_2.19.2.F.2021'
                  WHEN COLLECT_TYPE = 284 THEN
                   'G11_1_2.19.3.F.2021'
                  WHEN COLLECT_TYPE = 285 THEN
                   'G11_1_2.19.4.F.2021'
                  WHEN COLLECT_TYPE = 286 THEN
                   'G11_1_2.19.5.F.2021'
                  WHEN COLLECT_TYPE = 287 THEN
                   'G11_1_2.19.6.F.2021'
                  WHEN COLLECT_TYPE = 288 THEN
                   'G11_1_2.20.1.F.2021'
                  WHEN COLLECT_TYPE = 289 THEN
                   'G11_1_2.1.1.G.2021'
                  WHEN COLLECT_TYPE = 290 THEN
                   'G11_1_2.1.2.G.2021'
                  WHEN COLLECT_TYPE = 291 THEN
                   'G11_1_2.1.3.G.2021'
                  WHEN COLLECT_TYPE = 292 THEN
                   'G11_1_2.1.4.G.2021'
                  WHEN COLLECT_TYPE = 293 THEN
                   'G11_1_2.1.5.G.2021'
                  WHEN COLLECT_TYPE = 294 THEN
                   'G11_1_2.2.1.G.2021'
                  WHEN COLLECT_TYPE = 295 THEN
                   'G11_1_2.2.2.G.2021'
                  WHEN COLLECT_TYPE = 296 THEN
                   'G11_1_2.2.3.G.2021'
                  WHEN COLLECT_TYPE = 297 THEN
                   'G11_1_2.2.4.G.2021'
                  WHEN COLLECT_TYPE = 298 THEN
                   'G11_1_2.2.5.G.2021'
                  WHEN COLLECT_TYPE = 299 THEN
                   'G11_1_2.2.6.G.2021'
                  WHEN COLLECT_TYPE = 300 THEN
                   'G11_1_2.2.7.G.2021'
                  WHEN COLLECT_TYPE = 301 THEN
                   'G11_1_2.3.1.G.2021'
                  WHEN COLLECT_TYPE = 302 THEN
                   'G11_1_2.3.2.G.2021'
                  WHEN COLLECT_TYPE = 303 THEN
                   'G11_1_2.3.3.G.2021'
                  WHEN COLLECT_TYPE = 304 THEN
                   'G11_1_2.3.4.G.2021'
                  WHEN COLLECT_TYPE = 305 THEN
                   'G11_1_2.3.5.G.2021'
                  WHEN COLLECT_TYPE = 306 THEN
                   'G11_1_2.3.6.G.2021'
                  WHEN COLLECT_TYPE = 307 THEN
                   'G11_1_2.3.7.G.2021'
                  WHEN COLLECT_TYPE = 308 THEN
                   'G11_1_2.3.8.G.2021'
                  WHEN COLLECT_TYPE = 309 THEN
                   'G11_1_2.3.9.G.2021'
                  WHEN COLLECT_TYPE = 310 THEN
                   'G11_1_2.3.10.G.2021'
                  WHEN COLLECT_TYPE = 311 THEN
                   'G11_1_2.3.11.G.2021'
                  WHEN COLLECT_TYPE = 312 THEN
                   'G11_1_2.3.12.G.2021'
                  WHEN COLLECT_TYPE = 313 THEN
                   'G11_1_2.3.13.G.2021'
                  WHEN COLLECT_TYPE = 314 THEN
                   'G11_1_2.3.14.G.2021'
                  WHEN COLLECT_TYPE = 315 THEN
                   'G11_1_2.3.15.G.2021'
                  WHEN COLLECT_TYPE = 316 THEN
                   'G11_1_2.3.16.G.2021'
                  WHEN COLLECT_TYPE = 317 THEN
                   'G11_1_2.3.17.G.2021'
                  WHEN COLLECT_TYPE = 318 THEN
                   'G11_1_2.3.18.G.2021'
                  WHEN COLLECT_TYPE = 319 THEN
                   'G11_1_2.3.19.G.2021'
                  WHEN COLLECT_TYPE = 320 THEN
                   'G11_1_2.3.20.G.2021'
                  WHEN COLLECT_TYPE = 321 THEN
                   'G11_1_2.3.21.G.2021'
                  WHEN COLLECT_TYPE = 322 THEN
                   'G11_1_2.3.22.G.2021'
                  WHEN COLLECT_TYPE = 323 THEN
                   'G11_1_2.3.23.G.2021'
                  WHEN COLLECT_TYPE = 324 THEN
                   'G11_1_2.3.24.G.2021'
                  WHEN COLLECT_TYPE = 325 THEN
                   'G11_1_2.3.25.G.2021'
                  WHEN COLLECT_TYPE = 326 THEN
                   'G11_1_2.3.26.G.2021'
                  WHEN COLLECT_TYPE = 327 THEN
                   'G11_1_2.3.27.G.2021'
                  WHEN COLLECT_TYPE = 328 THEN
                   'G11_1_2.3.28.G.2021'
                  WHEN COLLECT_TYPE = 329 THEN
                   'G11_1_2.3.29.G.2021'
                  WHEN COLLECT_TYPE = 330 THEN
                   'G11_1_2.3.30.G.2021'
                  WHEN COLLECT_TYPE = 331 THEN
                   'G11_1_2.3.31.G.2021'
                  WHEN COLLECT_TYPE = 332 THEN
                   'G11_1_2.4.1.G.2021'
                  WHEN COLLECT_TYPE = 333 THEN
                   'G11_1_2.4.2.G.2021'
                  WHEN COLLECT_TYPE = 334 THEN
                   'G11_1_2.4.3.G.2021'
                  WHEN COLLECT_TYPE = 335 THEN
                   'G11_1_2.5.1.G.2021'
                  WHEN COLLECT_TYPE = 336 THEN
                   'G11_1_2.5.2.G.2021'
                  WHEN COLLECT_TYPE = 337 THEN
                   'G11_1_2.5.3.G.2021'
                  WHEN COLLECT_TYPE = 338 THEN
                   'G11_1_2.5.4.G.2021'
                  WHEN COLLECT_TYPE = 339 THEN
                   'G11_1_2.6.1.G.2021'
                  WHEN COLLECT_TYPE = 340 THEN
                   'G11_1_2.6.2.G.2021'
                  WHEN COLLECT_TYPE = 341 THEN
                   'G11_1_2.7.1.G.2021'
                  WHEN COLLECT_TYPE = 342 THEN
                   'G11_1_2.7.2.G.2021'
                  WHEN COLLECT_TYPE = 343 THEN
                   'G11_1_2.7.3.G.2021'
                  WHEN COLLECT_TYPE = 344 THEN
                   'G11_1_2.7.4.G.2021'
                  WHEN COLLECT_TYPE = 345 THEN
                   'G11_1_2.7.5.G.2021'
                  WHEN COLLECT_TYPE = 346 THEN
                   'G11_1_2.7.6.G.2021'
                  WHEN COLLECT_TYPE = 347 THEN
                   'G11_1_2.7.7.G.2021'
                  WHEN COLLECT_TYPE = 348 THEN
                   'G11_1_2.7.8.G.2021'
                  WHEN COLLECT_TYPE = 349 THEN
                   'G11_1_2.8.1.G.2021'
                  WHEN COLLECT_TYPE = 350 THEN
                   'G11_1_2.8.2.G.2021'
                  WHEN COLLECT_TYPE = 351 THEN
                   'G11_1_2.9.1.G.2021'
                  WHEN COLLECT_TYPE = 352 THEN
                   'G11_1_2.9.2.G.2021'
                  WHEN COLLECT_TYPE = 353 THEN
                   'G11_1_2.9.3.G.2021'
                  WHEN COLLECT_TYPE = 354 THEN
                   'G11_1_2.10.1.G.2021'
                  WHEN COLLECT_TYPE = 355 THEN
                   'G11_1_2.10.2.G.2021'
                  WHEN COLLECT_TYPE = 356 THEN
                   'G11_1_2.10.3.G.2021'
                  WHEN COLLECT_TYPE = 357 THEN
                   'G11_1_2.10.4.G.2021'
                  WHEN COLLECT_TYPE = 358 THEN
                   'G11_1_2.11.1.G.2021'
                  WHEN COLLECT_TYPE = 359 THEN
                   'G11_1_2.12.1.G.2021'
                  WHEN COLLECT_TYPE = 360 THEN
                   'G11_1_2.12.2.G.2021'
                  WHEN COLLECT_TYPE = 361 THEN
                   'G11_1_2.13.1.G.2021'
                  WHEN COLLECT_TYPE = 362 THEN
                   'G11_1_2.13.2.G.2021'
                  WHEN COLLECT_TYPE = 363 THEN
                   'G11_1_2.13.3.G.2021'
                  WHEN COLLECT_TYPE = 364 THEN
                   'G11_1_2.14.1.G.2021'
                  WHEN COLLECT_TYPE = 365 THEN
                   'G11_1_2.14.2.G.2021'
                  WHEN COLLECT_TYPE = 366 THEN
                   'G11_1_2.14.3.G.2021'
                  WHEN COLLECT_TYPE = 493 THEN
                   'G11_1_2.14.4.G.2021'
                  WHEN COLLECT_TYPE = 367 THEN
                   'G11_1_2.15.1.G.2021'
                  WHEN COLLECT_TYPE = 368 THEN
                   'G11_1_2.15.2.G.2021'
                  WHEN COLLECT_TYPE = 369 THEN
                   'G11_1_2.15.3.G.2021'
                  WHEN COLLECT_TYPE = 370 THEN
                   'G11_1_2.16.1.G.2021'
                  WHEN COLLECT_TYPE = 371 THEN
                   'G11_1_2.17.1.G.2021'
                  WHEN COLLECT_TYPE = 372 THEN
                   'G11_1_2.17.2.G.2021'
                  WHEN COLLECT_TYPE = 373 THEN
                   'G11_1_2.18.1.G.2021'
                  WHEN COLLECT_TYPE = 374 THEN
                   'G11_1_2.18.2.G.2021'
                  WHEN COLLECT_TYPE = 375 THEN
                   'G11_1_2.18.3.G.2021'
                  WHEN COLLECT_TYPE = 376 THEN
                   'G11_1_2.18.4.G.2021'
                  WHEN COLLECT_TYPE = 377 THEN
                   'G11_1_2.18.5.G.2021'
                  WHEN COLLECT_TYPE = 378 THEN
                   'G11_1_2.19.1.G.2021'
                  WHEN COLLECT_TYPE = 379 THEN
                   'G11_1_2.19.2.G.2021'
                  WHEN COLLECT_TYPE = 380 THEN
                   'G11_1_2.19.3.G.2021'
                  WHEN COLLECT_TYPE = 381 THEN
                   'G11_1_2.19.4.G.2021'
                  WHEN COLLECT_TYPE = 382 THEN
                   'G11_1_2.19.5.G.2021'
                  WHEN COLLECT_TYPE = 383 THEN
                   'G11_1_2.19.6.G.2021'
                  WHEN COLLECT_TYPE = 384 THEN
                   'G11_1_2.20.1.G.2021'
                  WHEN COLLECT_TYPE = 385 THEN
                   'G11_1_2.1.1.H.2021'
                  WHEN COLLECT_TYPE = 386 THEN
                   'G11_1_2.1.2.H.2021'
                  WHEN COLLECT_TYPE = 387 THEN
                   'G11_1_2.1.3.H.2021'
                  WHEN COLLECT_TYPE = 388 THEN
                   'G11_1_2.1.4.H.2021'
                  WHEN COLLECT_TYPE = 389 THEN
                   'G11_1_2.1.5.H.2021'
                  WHEN COLLECT_TYPE = 390 THEN
                   'G11_1_2.2.1.H.2021'
                  WHEN COLLECT_TYPE = 391 THEN
                   'G11_1_2.2.2.H.2021'
                  WHEN COLLECT_TYPE = 392 THEN
                   'G11_1_2.2.3.H.2021'
                  WHEN COLLECT_TYPE = 393 THEN
                   'G11_1_2.2.4.H.2021'
                  WHEN COLLECT_TYPE = 394 THEN
                   'G11_1_2.2.5.H.2021'
                  WHEN COLLECT_TYPE = 395 THEN
                   'G11_1_2.2.6.H.2021'
                  WHEN COLLECT_TYPE = 396 THEN
                   'G11_1_2.2.7.H.2021'
                  WHEN COLLECT_TYPE = 397 THEN
                   'G11_1_2.3.1.H.2021'
                  WHEN COLLECT_TYPE = 398 THEN
                   'G11_1_2.3.2.H.2021'
                  WHEN COLLECT_TYPE = 399 THEN
                   'G11_1_2.3.3.H.2021'
                  WHEN COLLECT_TYPE = 400 THEN
                   'G11_1_2.3.4.H.2021'
                  WHEN COLLECT_TYPE = 401 THEN
                   'G11_1_2.3.5.H.2021'
                  WHEN COLLECT_TYPE = 402 THEN
                   'G11_1_2.3.6.H.2021'
                  WHEN COLLECT_TYPE = 403 THEN
                   'G11_1_2.3.7.H.2021'
                  WHEN COLLECT_TYPE = 404 THEN
                   'G11_1_2.3.8.H.2021'
                  WHEN COLLECT_TYPE = 405 THEN
                   'G11_1_2.3.9.H.2021'
                  WHEN COLLECT_TYPE = 406 THEN
                   'G11_1_2.3.10.H.2021'
                  WHEN COLLECT_TYPE = 407 THEN
                   'G11_1_2.3.11.H.2021'
                  WHEN COLLECT_TYPE = 408 THEN
                   'G11_1_2.3.12.H.2021'
                  WHEN COLLECT_TYPE = 409 THEN
                   'G11_1_2.3.13.H.2021'
                  WHEN COLLECT_TYPE = 410 THEN
                   'G11_1_2.3.14.H.2021'
                  WHEN COLLECT_TYPE = 411 THEN
                   'G11_1_2.3.15.H.2021'
                  WHEN COLLECT_TYPE = 412 THEN
                   'G11_1_2.3.16.H.2021'
                  WHEN COLLECT_TYPE = 413 THEN
                   'G11_1_2.3.17.H.2021'
                  WHEN COLLECT_TYPE = 414 THEN
                   'G11_1_2.3.18.H.2021'
                  WHEN COLLECT_TYPE = 415 THEN
                   'G11_1_2.3.19.H.2021'
                  WHEN COLLECT_TYPE = 416 THEN
                   'G11_1_2.3.20.H.2021'
                  WHEN COLLECT_TYPE = 417 THEN
                   'G11_1_2.3.21.H.2021'
                  WHEN COLLECT_TYPE = 418 THEN
                   'G11_1_2.3.22.H.2021'
                  WHEN COLLECT_TYPE = 419 THEN
                   'G11_1_2.3.23.H.2021'
                  WHEN COLLECT_TYPE = 420 THEN
                   'G11_1_2.3.24.H.2021'
                  WHEN COLLECT_TYPE = 421 THEN
                   'G11_1_2.3.25.H.2021'
                  WHEN COLLECT_TYPE = 422 THEN
                   'G11_1_2.3.26.H.2021'
                  WHEN COLLECT_TYPE = 423 THEN
                   'G11_1_2.3.27.H.2021'
                  WHEN COLLECT_TYPE = 424 THEN
                   'G11_1_2.3.28.H.2021'
                  WHEN COLLECT_TYPE = 425 THEN
                   'G11_1_2.3.29.H.2021'
                  WHEN COLLECT_TYPE = 426 THEN
                   'G11_1_2.3.30.H.2021'
                  WHEN COLLECT_TYPE = 427 THEN
                   'G11_1_2.3.31.H.2021'
                  WHEN COLLECT_TYPE = 428 THEN
                   'G11_1_2.4.1.H.2021'
                  WHEN COLLECT_TYPE = 429 THEN
                   'G11_1_2.4.2.H.2021'
                  WHEN COLLECT_TYPE = 430 THEN
                   'G11_1_2.4.3.H.2021'
                  WHEN COLLECT_TYPE = 431 THEN
                   'G11_1_2.5.1.H.2021'
                  WHEN COLLECT_TYPE = 432 THEN
                   'G11_1_2.5.2.H.2021'
                  WHEN COLLECT_TYPE = 433 THEN
                   'G11_1_2.5.3.H.2021'
                  WHEN COLLECT_TYPE = 434 THEN
                   'G11_1_2.5.4.H.2021'
                  WHEN COLLECT_TYPE = 435 THEN
                   'G11_1_2.6.1.H.2021'
                  WHEN COLLECT_TYPE = 436 THEN
                   'G11_1_2.6.2.H.2021'
                  WHEN COLLECT_TYPE = 437 THEN
                   'G11_1_2.7.1.H.2021'
                  WHEN COLLECT_TYPE = 438 THEN
                   'G11_1_2.7.2.H.2021'
                  WHEN COLLECT_TYPE = 439 THEN
                   'G11_1_2.7.3.H.2021'
                  WHEN COLLECT_TYPE = 440 THEN
                   'G11_1_2.7.4.H.2021'
                  WHEN COLLECT_TYPE = 441 THEN
                   'G11_1_2.7.5.H.2021'
                  WHEN COLLECT_TYPE = 442 THEN
                   'G11_1_2.7.6.H.2021'
                  WHEN COLLECT_TYPE = 443 THEN
                   'G11_1_2.7.7.H.2021'
                  WHEN COLLECT_TYPE = 444 THEN
                   'G11_1_2.7.8.H.2021'
                  WHEN COLLECT_TYPE = 445 THEN
                   'G11_1_2.8.1.H.2021'
                  WHEN COLLECT_TYPE = 446 THEN
                   'G11_1_2.8.2.H.2021'
                  WHEN COLLECT_TYPE = 447 THEN
                   'G11_1_2.9.1.H.2021'
                  WHEN COLLECT_TYPE = 448 THEN
                   'G11_1_2.9.2.H.2021'
                  WHEN COLLECT_TYPE = 449 THEN
                   'G11_1_2.9.3.H.2021'
                  WHEN COLLECT_TYPE = 450 THEN
                   'G11_1_2.10.1.H.2021'
                  WHEN COLLECT_TYPE = 451 THEN
                   'G11_1_2.10.2.H.2021'
                  WHEN COLLECT_TYPE = 452 THEN
                   'G11_1_2.10.3.H.2021'
                  WHEN COLLECT_TYPE = 453 THEN
                   'G11_1_2.10.4.H.2021'
                  WHEN COLLECT_TYPE = 454 THEN
                   'G11_1_2.11.1.H.2021'
                  WHEN COLLECT_TYPE = 455 THEN
                   'G11_1_2.12.1.H.2021'
                  WHEN COLLECT_TYPE = 456 THEN
                   'G11_1_2.12.2.H.2021'
                  WHEN COLLECT_TYPE = 457 THEN
                   'G11_1_2.13.1.H.2021'
                  WHEN COLLECT_TYPE = 458 THEN
                   'G11_1_2.13.2.H.2021'
                  WHEN COLLECT_TYPE = 459 THEN
                   'G11_1_2.13.3.H.2021'
                  WHEN COLLECT_TYPE = 460 THEN
                   'G11_1_2.14.1.H.2021'
                  WHEN COLLECT_TYPE = 461 THEN
                   'G11_1_2.14.2.H.2021'
                  WHEN COLLECT_TYPE = 462 THEN
                   'G11_1_2.14.3.H.2021'
                  WHEN COLLECT_TYPE = 494 THEN
                   'G11_1_2.14.4.H.2021'
                  WHEN COLLECT_TYPE = 463 THEN
                   'G11_1_2.15.1.H.2021'
                  WHEN COLLECT_TYPE = 464 THEN
                   'G11_1_2.15.2.H.2021'
                  WHEN COLLECT_TYPE = 465 THEN
                   'G11_1_2.15.3.H.2021'
                  WHEN COLLECT_TYPE = 466 THEN
                   'G11_1_2.16.1.H.2021'
                  WHEN COLLECT_TYPE = 467 THEN
                   'G11_1_2.17.1.H.2021'
                  WHEN COLLECT_TYPE = 468 THEN
                   'G11_1_2.17.2.H.2021'
                  WHEN COLLECT_TYPE = 469 THEN
                   'G11_1_2.18.1.H.2021'
                  WHEN COLLECT_TYPE = 470 THEN
                   'G11_1_2.18.2.H.2021'
                  WHEN COLLECT_TYPE = 471 THEN
                   'G11_1_2.18.3.H.2021'
                  WHEN COLLECT_TYPE = 472 THEN
                   'G11_1_2.18.4.H.2021'
                  WHEN COLLECT_TYPE = 473 THEN
                   'G11_1_2.18.5.H.2021'
                  WHEN COLLECT_TYPE = 474 THEN
                   'G11_1_2.19.1.H.2021'
                  WHEN COLLECT_TYPE = 475 THEN
                   'G11_1_2.19.2.H.2021'
                  WHEN COLLECT_TYPE = 476 THEN
                   'G11_1_2.19.3.H.2021'
                  WHEN COLLECT_TYPE = 477 THEN
                   'G11_1_2.19.4.H.2021'
                  WHEN COLLECT_TYPE = 478 THEN
                   'G11_1_2.19.5.H.2021'
                  WHEN COLLECT_TYPE = 479 THEN
                   'G11_1_2.19.6.H.2021'
                  WHEN COLLECT_TYPE = 480 THEN
                   'G11_1_2.20.1.H.2021'
                END
) q_0
INSERT INTO `G11_1_2.8.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.21.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.5.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.16.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.28.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.8.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.13.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.7.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.20.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.16.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.8.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.30.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.21.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.17.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.26.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.12.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.4.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.20.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.24.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.5.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.22.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.17.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.5.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.5.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.9.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.4.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.4.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.3.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.16.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.4.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.17.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.14.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.12.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.18.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.12.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.4.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.23.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.17.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.7.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.10.4.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.11.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.21.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.3.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.4.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.4.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.13.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.4.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.4.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.12.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.26.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.5.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.29.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.16.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.9.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.12.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.18.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.3.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.29.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.9.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.3.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.5.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.23.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.17.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.4.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.12.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.14.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.17.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.8.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.5.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.5.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.11.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.3.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.10.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.8.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.10.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.4.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.24.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.18.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.15.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.5.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.3.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.28.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.25.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.22.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.11.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.12.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.12.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.4.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.8.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.31.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.6.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.3.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.26.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.30.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.16.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.8.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.11.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.4.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.3.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.18.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.6.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.4.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.17.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.4.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.18.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.6.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.27.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.4.3.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.20.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.13.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.7.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.5.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.25.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.7.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.4.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.23.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.19.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.15.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.7.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.3.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.12.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.3.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.5.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.28.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.29.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.11.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.10.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.7.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.3.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.11.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.17.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.12.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.23.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.3.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.15.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.5.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.13.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.4.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.30.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.4.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.26.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.24.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.29.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.21.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.27.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.3.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.6.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.17.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.11.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.4.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.11.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.17.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.4.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.4.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.4.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.2.4.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.6.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.16.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.11.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.27.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.16.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.4.3.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.16.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.3.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.6.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.17.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.3.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.3.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.12.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.22.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.17.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.5.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.14.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.10.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.13.3.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.1.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.24.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.2.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.5.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.8.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.3.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.14.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.3.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.5.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.10.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.1.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.31.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.2.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.6.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.2.H.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.15.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.18.4.C.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.3.15.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.7.2.G.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.9.3.D.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_2.14.2.F.2021` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 1: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN FLAG_TMP = '1' THEN
                'G11_1_4.1.C'
               WHEN FLAG_TMP = '2' THEN
                'G11_1_4.1.D'
               WHEN FLAG_TMP = '3' THEN
                'G11_1_4.1.F'
               WHEN FLAG_TMP = '4' THEN
                'G11_1_4.1.G'
               WHEN FLAG_TMP = '5' THEN
                'G11_1_4.1.H'
             END AS ITEM_NUM, --指标号
             SUM(NVL(LOAN_ACCT_BAL_RMB, 0) + NVL(OD_LOAN_ACCT_BAL_RMB, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_A_REPT_LOAN_BAL_G1101
       WHERE FLAG_TMP IN ('1', '2', '3', '4', '5')
       GROUP BY ORG_NUM,
                CASE
                  WHEN FLAG_TMP = '1' THEN
                   'G11_1_4.1.C'
                  WHEN FLAG_TMP = '2' THEN
                   'G11_1_4.1.D'
                  WHEN FLAG_TMP = '3' THEN
                   'G11_1_4.1.F'
                  WHEN FLAG_TMP = '4' THEN
                   'G11_1_4.1.G'
                  WHEN FLAG_TMP = '5' THEN
                   'G11_1_4.1.H'
                END
) q_1
INSERT INTO `G11_1_4.1.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.1.C` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.1.D` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 2: 共 5 个指标 ==========
FROM (
SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_2.21.4.C'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_2.21.4.D'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_2.21.4.F'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_2.21.4.G'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_2.21.4.H'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL * u.ccy_rate) +
             SUM(INT_ADJEST_AMT * u.ccy_rate) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN a
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP LIKE '01%'
         AND A.ACCT_TYP NOT LIKE '0102%'
         AND A.ACCT_TYP NOT IN ('010301', '010101', '010199')
         AND A.FUND_USE_LOC_CD = 'I'
         and A.acct_typ not LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_STS <> '3'
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_2.21.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_2.21.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_2.21.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_2.21.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_2.21.4.H'
                END
) q_2
INSERT INTO `G11_1_2.21.4.H` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.4.D` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.4.G` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.4.C` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.4.F` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *;

-- ========== 逻辑组 3: 共 5 个指标 ==========
FROM (
SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G11_1_2.21.1.H'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G11_1_2.21.1.G'
               WHEN LXQKQS = 4 THEN
                'G11_1_2.21.1.F'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G11_1_2.21.1.D'
               ELSE
                'G11_1_2.21.1.C'
             END AS COLLECT_TYPE,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY  CASE
               WHEN LXQKQS >= 7 THEN
                'G11_1_2.21.1.H'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G11_1_2.21.1.G'
               WHEN LXQKQS = 4 THEN
                'G11_1_2.21.1.F'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G11_1_2.21.1.D'
               ELSE
                'G11_1_2.21.1.C'
             END
) q_3
INSERT INTO `G11_1_2.21.1.G` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.1.F` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.1.C` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.1.H` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.1.D` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *;

-- 指标: G11_1_4.5.H
--==================================================
    --   G1101 4.4逾期91天到180天贷款-4.7逾期361天以上贷款
    --==================================================
    INSERT INTO `G11_1_4.5.H`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN OD_DAY = '180D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.3.H'
                END)
               WHEN OD_DAY = '270D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.4.H'
                END)
               WHEN OD_DAY = '360D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.5.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.5.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.5.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.5.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.5.H'
                END)
               WHEN OD_DAY = '360AD' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.6.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.6.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.6.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.6.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.6.H'
                END)
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT CASE
                       WHEN A.OD_DAYS > 360 THEN
                        '360AD'
                       WHEN A.OD_DAYS IS NULL THEN
                        '360AD' --shiwenbo by 20170313-OD_DAY 增加逾期天数为空的判断，将数据放入一年以上
                       WHEN A.OD_DAYS > 270 THEN
                        '360D'
                       WHEN A.OD_DAYS > 180 THEN
                        '270D'
                       WHEN A.OD_DAYS > 90 THEN
                        '180D'
                       WHEN A.OD_DAYS > 60 THEN
                        '60D' -- 20200114 modify ljp 增加 60天 期限
                       WHEN A.OD_DAYS > 30 THEN
                        '90D'
                       WHEN A.OD_DAYS > 0 THEN
                        '30D'
                     END AS OD_DAY,
                     A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                     A.INT_ADJEST_AMT AS INT_ADJEST_AMT,
                     A.CURR_CD AS CURR_CD,
                     A.OD_FLG AS OD_FLG,
                     A.DATA_DATE AS DATA_DATE,
                     A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                     A.ACCT_STS AS ACCT_STS,
                     A.ORG_NUM AS ORG_NUM,
                     A.ACCT_TYP AS ACCT_TYP
                FROM SMTMODS_L_ACCT_LOAN A
                where A.CANCEL_FLG <> 'Y'
                  AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        ) A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAY IN ('180D', '270D', '360D', '360AD')
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP not LIKE '90%'
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN OD_DAY = '180D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.3.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.3.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.3.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.3.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.3.H'
                   END)
                  WHEN OD_DAY = '270D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.4.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.4.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.4.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.4.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.4.H'
                   END)
                  WHEN OD_DAY = '360D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.5.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.5.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.5.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.5.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.5.H'
                   END)
                  WHEN OD_DAY = '360AD' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.6.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.6.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.6.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.6.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.6.H'
                   END)
                END;

INSERT INTO `G11_1_4.5.H`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.5.H' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
             and LXQKQS in (10,11,12);


-- ========== 逻辑组 5: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_6..C.091231'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_6..D.091231'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_6..F.091231'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_6..G.091231'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_6..H.091231'
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.EXTENDTERM_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.ACCT_STS <> '3'
         and A.CANCEL_FLG <> 'Y'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_6..C.091231'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_6..D.091231'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_6..F.091231'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_6..G.091231'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_6..H.091231'
                END
) q_5
INSERT INTO `G11_1_6..H.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_6..D.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_6..G.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_6..F.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_6..C.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 6: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN LOAN_GRADE_CD = '3' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.F'
         WHEN LOAN_GRADE_CD = '4' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.G'
         WHEN LOAN_GRADE_CD = '5' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.H'
          --2024年新增制度指标G11_1_5.2.D.2024 alter by shiyu 20240314
          --5.2期间新重组方案 关注类
          WHEN LOAN_GRADE_CD = '2' AND
              DRAWDOWN_DT >
             SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.D.2024'
          -- 20250318 2025年制度升级
          WHEN LOAN_GRADE_CD = '1' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.C.2025'

       END AS ITEM_NUM, --指标号
       SUM(LOAN_ACCT_BAL * U.CCY_RATE) + SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE RESCHED_FLG = 'Y' --重组标志
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG = 'N'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     AND  DRAWDOWN_DT > SUBSTR(I_DATADATE, 1, 4) || '0101'
  
       GROUP BY ORG_NUM,
                CASE
         WHEN LOAN_GRADE_CD = '3' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.F'
         WHEN LOAN_GRADE_CD = '4' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.G'
         WHEN LOAN_GRADE_CD = '5' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.H'
          --2024年新增制度指标G11_1_5.2.D.2024 alter by shiyu 20240314
          --5.2期间新重组方案 关注类
          WHEN LOAN_GRADE_CD = '2' AND
              DRAWDOWN_DT >
             SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.D.2024'
          -- 20250318 2025年制度升级
          WHEN LOAN_GRADE_CD = '1' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.C.2025'

       END
) q_6
INSERT INTO `G11_1_5.2.G` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.2.D.2024` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.2.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.2.H` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.2.C.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 7: 共 5 个指标 ==========
FROM (
SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_2.21.3.C'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_2.21.3.D'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_2.21.3.F'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_2.21.3.G'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_2.21.3.H'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP LIKE '0101%'
         AND A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_2.21.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_2.21.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_2.21.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_2.21.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_2.21.3.H'
                END
) q_7
INSERT INTO `G11_1_2.21.3.F` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.3.D` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.3.C` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.3.G` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.3.H` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *;

-- ========== 逻辑组 8: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.1.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.1.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.1.H'
  --2024年新增制度指标G11_1_5.1.D.2024 alter by shiyu 20240314
   --5.1年初重组贷款 关注类
         when A.LOAN_GRADE_CD = '2' THEN
           'G11_1_5.1.D.2024'
    ----20250318 2025年制度升级
         when A.LOAN_GRADE_CD = '1' THEN
           'G11_1_5.1.C.2025'
       END AS ITEM_NUM, --指标号
       SUM(LOAN_ACCT_BAL * U.CCY_RATE) + SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE RESCHED_FLG = 'Y'
         AND A.DATA_DATE = SUBSTR(I_DATADATE, 0, 4) - 1 || '1231'
         AND LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         /*AND A.ORG_NUM NOT LIKE '5100%'*/ --ADD 刘晟典
      --AND TO_CHAR(DRAWDOWN_DT,'YYYYMMDD') = SUBSTR(I_DATADATE, 0, 4) - 1 ||'1231'
       GROUP BY ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.1.F'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.1.G'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.1.H'
                  when A.LOAN_GRADE_CD = '2' THEN
                   'G11_1_5.1.D.2024'
                  when A.LOAN_GRADE_CD = '1' THEN
                   'G11_1_5.1.C.2025'
                END
) q_8
INSERT INTO `G11_1_5.1.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.1.H` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.1.C.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.1.D.2024` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.1.G` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 9: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.5.1.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.5.1.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.5.1.H'
          WHEN A.LOAN_GRADE_CD = '2' THEN
          'G11_1_5.5.1.D.2024'
          --20250318 2025年制度升级
           WHEN A.LOAN_GRADE_CD = '1' THEN
          'G11_1_5.5.1.C.2025'
       END AS ITEM_NUM, --指标号
       SUM(LOAN_ACCT_BAL * U.CCY_RATE) + SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN cbrc_TM_CBRC_G1101_TEMP1 C
          ON A.LOAN_NUM = C.LOAN_NUM
          AND A.ORG_NUM = C.ORG_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.RESCHED_FLG = 'Y'
         AND OD_DAYS > 90
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL      --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.5.1.F'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.5.1.G'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.5.1.H'
                  WHEN A.LOAN_GRADE_CD = '2' THEN
                   'G11_1_5.5.1.D.2024'
                    WHEN A.LOAN_GRADE_CD = '1' THEN
                   'G11_1_5.5.1.C.2025'
                END
) q_9
INSERT INTO `G11_1_5.5.1.H` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.5.1.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 10: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN FLAG_TMP = '1' THEN
                'G11_1_4.7.C'
               WHEN FLAG_TMP = '2' THEN
                'G11_1_4.7.D'
               WHEN FLAG_TMP = '3' THEN
                'G11_1_4.7.F'
               WHEN FLAG_TMP = '4' THEN
                'G11_1_4.7.G'
               WHEN FLAG_TMP = '5' THEN
                'G11_1_4.7.H'
             END AS ITEM_NUM, --指标号
             SUM(NVL(LOAN_ACCT_BAL_RMB, 0) + NVL(OD_LOAN_ACCT_BAL_RMB, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_A_REPT_LOAN_BAL_G1101
       WHERE FLAG_TMP IN ('1', '2', '3', '4', '5')
       GROUP BY ORG_NUM,
                CASE
                  WHEN FLAG_TMP = '1' THEN
                   'G11_1_4.7.C'
                  WHEN FLAG_TMP = '2' THEN
                   'G11_1_4.7.D'
                  WHEN FLAG_TMP = '3' THEN
                   'G11_1_4.7.F'
                  WHEN FLAG_TMP = '4' THEN
                   'G11_1_4.7.G'
                  WHEN FLAG_TMP = '5' THEN
                   'G11_1_4.7.H'
                END
) q_10
INSERT INTO `G11_1_4.7.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.7.G` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.7.D` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: G11_1_4.3.F
--==================================================
    --   G1101 4.4逾期91天到180天贷款-4.7逾期361天以上贷款
    --==================================================
    INSERT INTO `G11_1_4.3.F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN OD_DAY = '180D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.3.H'
                END)
               WHEN OD_DAY = '270D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.4.H'
                END)
               WHEN OD_DAY = '360D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.5.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.5.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.5.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.5.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.5.H'
                END)
               WHEN OD_DAY = '360AD' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.6.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.6.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.6.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.6.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.6.H'
                END)
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT CASE
                       WHEN A.OD_DAYS > 360 THEN
                        '360AD'
                       WHEN A.OD_DAYS IS NULL THEN
                        '360AD' --shiwenbo by 20170313-OD_DAY 增加逾期天数为空的判断，将数据放入一年以上
                       WHEN A.OD_DAYS > 270 THEN
                        '360D'
                       WHEN A.OD_DAYS > 180 THEN
                        '270D'
                       WHEN A.OD_DAYS > 90 THEN
                        '180D'
                       WHEN A.OD_DAYS > 60 THEN
                        '60D' -- 20200114 modify ljp 增加 60天 期限
                       WHEN A.OD_DAYS > 30 THEN
                        '90D'
                       WHEN A.OD_DAYS > 0 THEN
                        '30D'
                     END AS OD_DAY,
                     A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                     A.INT_ADJEST_AMT AS INT_ADJEST_AMT,
                     A.CURR_CD AS CURR_CD,
                     A.OD_FLG AS OD_FLG,
                     A.DATA_DATE AS DATA_DATE,
                     A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                     A.ACCT_STS AS ACCT_STS,
                     A.ORG_NUM AS ORG_NUM,
                     A.ACCT_TYP AS ACCT_TYP
                FROM SMTMODS_L_ACCT_LOAN A
                where A.CANCEL_FLG <> 'Y'
                  AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        ) A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAY IN ('180D', '270D', '360D', '360AD')
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP not LIKE '90%'
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN OD_DAY = '180D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.3.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.3.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.3.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.3.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.3.H'
                   END)
                  WHEN OD_DAY = '270D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.4.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.4.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.4.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.4.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.4.H'
                   END)
                  WHEN OD_DAY = '360D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.5.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.5.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.5.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.5.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.5.H'
                   END)
                  WHEN OD_DAY = '360AD' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.6.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.6.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.6.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.6.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.6.H'
                   END)
                END;

INSERT INTO `G11_1_4.3.F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.3.F' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = t.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         and LXQKQS = 4;


-- ========== 逻辑组 12: 共 5 个指标 ==========
FROM (
SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_2.21.2.C'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_2.21.2.D'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_2.21.2.F'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_2.21.2.G'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_2.21.2.H'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP = '010301'
         AND a.acct_typ not LIKE '90%'
         AND A.FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_2.21.2.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_2.21.2.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_2.21.2.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_2.21.2.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_2.21.2.H'
                END
) q_12
INSERT INTO `G11_1_2.21.2.H` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.2.F` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.2.D` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.2.C` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *
INSERT INTO `G11_1_2.21.2.G` (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
SELECT *;

-- ========== 逻辑组 13: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN OD_DAY = '180D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.3.H'
                END)
               WHEN OD_DAY = '270D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.4.H'
                END)
               WHEN OD_DAY = '360D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.5.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.5.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.5.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.5.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.5.H'
                END)
               WHEN OD_DAY = '360AD' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.6.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.6.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.6.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.6.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.6.H'
                END)
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT CASE
                       WHEN A.OD_DAYS > 360 THEN
                        '360AD'
                       WHEN A.OD_DAYS IS NULL THEN
                        '360AD' --shiwenbo by 20170313-OD_DAY 增加逾期天数为空的判断，将数据放入一年以上
                       WHEN A.OD_DAYS > 270 THEN
                        '360D'
                       WHEN A.OD_DAYS > 180 THEN
                        '270D'
                       WHEN A.OD_DAYS > 90 THEN
                        '180D'
                       WHEN A.OD_DAYS > 60 THEN
                        '60D' -- 20200114 modify ljp 增加 60天 期限
                       WHEN A.OD_DAYS > 30 THEN
                        '90D'
                       WHEN A.OD_DAYS > 0 THEN
                        '30D'
                     END AS OD_DAY,
                     A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                     A.INT_ADJEST_AMT AS INT_ADJEST_AMT,
                     A.CURR_CD AS CURR_CD,
                     A.OD_FLG AS OD_FLG,
                     A.DATA_DATE AS DATA_DATE,
                     A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                     A.ACCT_STS AS ACCT_STS,
                     A.ORG_NUM AS ORG_NUM,
                     A.ACCT_TYP AS ACCT_TYP
                FROM SMTMODS_L_ACCT_LOAN A
                where A.CANCEL_FLG <> 'Y'
                  AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        ) A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAY IN ('180D', '270D', '360D', '360AD')
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP not LIKE '90%'
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN OD_DAY = '180D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.3.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.3.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.3.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.3.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.3.H'
                   END)
                  WHEN OD_DAY = '270D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.4.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.4.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.4.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.4.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.4.H'
                   END)
                  WHEN OD_DAY = '360D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.5.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.5.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.5.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.5.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.5.H'
                   END)
                  WHEN OD_DAY = '360AD' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.6.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.6.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.6.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.6.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.6.H'
                   END)
                END
) q_13
INSERT INTO `G11_1_4.5.G` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.3.H` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.3.D` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.4.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.4.G` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 14: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       B.ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.4.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.4.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.4.H'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'G11_1_5.4.D.2024'
          --20250318 2025年制度升级‘
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'G11_1_5.4.C.2025'
       END AS ITEM_NUM, --指标号
       SUM(B.PAY_AMT) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM CBRC_TM_CBRC_G1101_TEMP1 A
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
          ON A.LOAN_NUM = B.LOAN_NUM
          AND A.ORG_NUM = B.ORG_NUM
          AND SUBSTR(B.REPAY_DT,1,4)=SUBSTR(I_DATADATE,1,4)
       WHERE A.LOAN_GRADE_CD IN ('3', '4', '5','2','1')
       GROUP BY B.ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.4.F'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.4.G'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.4.H'
                  WHEN A.LOAN_GRADE_CD = '2' THEN
                    'G11_1_5.4.D.2024'
                  WHEN A.LOAN_GRADE_CD = '1' THEN
                    'G11_1_5.4.C.2025'
                END
) q_14
INSERT INTO `G11_1_5.4.D.2024` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.4.G` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.4.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.4.H` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.4.C.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 15: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             t.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G1101' AS REP_NUM,
              CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_7..C.091231'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_7..D.091231'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_7..F.091231'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_7..G.091231'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_7..H.091231'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL * U.CCY_RATE + INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3'
         and  t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY t.ORG_NUM, --机构号
                 CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_7..C.091231'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_7..D.091231'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_7..F.091231'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_7..G.091231'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_7..H.091231'
             END
) q_15
INSERT INTO `G11_1_7..G.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_7..D.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_7..H.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_7..F.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_7..C.091231` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 16: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.5.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.5.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.5.H'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'G11_1_5.5.D.2024'
          --20250318 2025年制度升级
          WHEN A.LOAN_GRADE_CD = '1' THEN
          'G11_1_5.5.C.2025'
       END AS ITEM_NUM, --指标号
       SUM(LOAN_ACCT_BAL * U.CCY_RATE) + SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN cbrc_TM_CBRC_G1101_TEMP1 C
          ON A.LOAN_NUM = C.LOAN_NUM
          AND A.ORG_NUM = C.ORG_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.RESCHED_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.5.F'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.5.G'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.5.H'
                  WHEN A.LOAN_GRADE_CD = '2' THEN
                   'G11_1_5.5.D.2024'
                   WHEN A.LOAN_GRADE_CD = '1' THEN
                    'G11_1_5.5.C.2025'
                END
) q_16
INSERT INTO `G11_1_5.5.C.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.5.D.2024` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.5.H` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.5.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_5.5.G` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: G11_1_4.4.H
--==================================================
    --   G1101 4.4逾期91天到180天贷款-4.7逾期361天以上贷款
    --==================================================
    INSERT INTO `G11_1_4.4.H`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN OD_DAY = '180D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.3.H'
                END)
               WHEN OD_DAY = '270D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.4.H'
                END)
               WHEN OD_DAY = '360D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.5.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.5.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.5.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.5.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.5.H'
                END)
               WHEN OD_DAY = '360AD' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.6.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.6.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.6.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.6.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.6.H'
                END)
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT CASE
                       WHEN A.OD_DAYS > 360 THEN
                        '360AD'
                       WHEN A.OD_DAYS IS NULL THEN
                        '360AD' --shiwenbo by 20170313-OD_DAY 增加逾期天数为空的判断，将数据放入一年以上
                       WHEN A.OD_DAYS > 270 THEN
                        '360D'
                       WHEN A.OD_DAYS > 180 THEN
                        '270D'
                       WHEN A.OD_DAYS > 90 THEN
                        '180D'
                       WHEN A.OD_DAYS > 60 THEN
                        '60D' -- 20200114 modify ljp 增加 60天 期限
                       WHEN A.OD_DAYS > 30 THEN
                        '90D'
                       WHEN A.OD_DAYS > 0 THEN
                        '30D'
                     END AS OD_DAY,
                     A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                     A.INT_ADJEST_AMT AS INT_ADJEST_AMT,
                     A.CURR_CD AS CURR_CD,
                     A.OD_FLG AS OD_FLG,
                     A.DATA_DATE AS DATA_DATE,
                     A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                     A.ACCT_STS AS ACCT_STS,
                     A.ORG_NUM AS ORG_NUM,
                     A.ACCT_TYP AS ACCT_TYP
                FROM SMTMODS_L_ACCT_LOAN A
                where A.CANCEL_FLG <> 'Y'
                  AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        ) A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAY IN ('180D', '270D', '360D', '360AD')
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP not LIKE '90%'
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN OD_DAY = '180D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.3.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.3.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.3.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.3.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.3.H'
                   END)
                  WHEN OD_DAY = '270D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.4.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.4.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.4.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.4.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.4.H'
                   END)
                  WHEN OD_DAY = '360D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.5.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.5.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.5.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.5.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.5.H'
                   END)
                  WHEN OD_DAY = '360AD' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.6.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.6.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.6.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.6.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.6.H'
                   END)
                END;

INSERT INTO `G11_1_4.4.H`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       ) --该部分开发未测试，且需上游提供欠本欠息日期字段
    --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.4.H' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
       /*  and t.p_od_date > t.i_od_date
         and ((D_DATADATE_CCY - t.i_od_date + 1) > 180 or
             (D_DATADATE_CCY - t.i_od_date + 1) < 271)*/
        and LXQKQS in (7,8,9);


-- 指标: G11_1_2.22..C.091231
--====================================================
    --   G1101 2.22 买断式转贴现
    --====================================================
    INSERT INTO `G11_1_2.22..C.091231`
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
      SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_2.22..C.091231'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_2.22..D.091231'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_2.22..F.091231'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_2.22..G.091231'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_2.22..H.091231'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       WHERE 
       SUBSTR(ITEM_CD,1,6) IN ('130102', '130105')
         AND FUND_USE_LOC_CD = 'I'
         AND DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_2.22..C.091231'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_2.22..D.091231'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_2.22..F.091231'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_2.22..G.091231'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_2.22..H.091231'
                END;


-- 指标: G11_1_4.3.G
--==================================================
    --   G1101 4.4逾期91天到180天贷款-4.7逾期361天以上贷款
    --==================================================
    INSERT INTO `G11_1_4.3.G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN OD_DAY = '180D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.3.H'
                END)
               WHEN OD_DAY = '270D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.4.H'
                END)
               WHEN OD_DAY = '360D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.5.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.5.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.5.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.5.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.5.H'
                END)
               WHEN OD_DAY = '360AD' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.6.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.6.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.6.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.6.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.6.H'
                END)
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT CASE
                       WHEN A.OD_DAYS > 360 THEN
                        '360AD'
                       WHEN A.OD_DAYS IS NULL THEN
                        '360AD' --shiwenbo by 20170313-OD_DAY 增加逾期天数为空的判断，将数据放入一年以上
                       WHEN A.OD_DAYS > 270 THEN
                        '360D'
                       WHEN A.OD_DAYS > 180 THEN
                        '270D'
                       WHEN A.OD_DAYS > 90 THEN
                        '180D'
                       WHEN A.OD_DAYS > 60 THEN
                        '60D' -- 20200114 modify ljp 增加 60天 期限
                       WHEN A.OD_DAYS > 30 THEN
                        '90D'
                       WHEN A.OD_DAYS > 0 THEN
                        '30D'
                     END AS OD_DAY,
                     A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                     A.INT_ADJEST_AMT AS INT_ADJEST_AMT,
                     A.CURR_CD AS CURR_CD,
                     A.OD_FLG AS OD_FLG,
                     A.DATA_DATE AS DATA_DATE,
                     A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                     A.ACCT_STS AS ACCT_STS,
                     A.ORG_NUM AS ORG_NUM,
                     A.ACCT_TYP AS ACCT_TYP
                FROM SMTMODS_L_ACCT_LOAN A
                where A.CANCEL_FLG <> 'Y'
                  AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        ) A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAY IN ('180D', '270D', '360D', '360AD')
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP not LIKE '90%'
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN OD_DAY = '180D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.3.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.3.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.3.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.3.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.3.H'
                   END)
                  WHEN OD_DAY = '270D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.4.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.4.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.4.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.4.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.4.H'
                   END)
                  WHEN OD_DAY = '360D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.5.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.5.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.5.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.5.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.5.H'
                   END)
                  WHEN OD_DAY = '360AD' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.6.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.6.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.6.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.6.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.6.H'
                   END)
                END;

INSERT INTO `G11_1_4.3.G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.3.G' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
          and LXQKQS in (5,6);


-- 指标: G11_1_4.6.H
--==================================================
    --   G1101 4.4逾期91天到180天贷款-4.7逾期361天以上贷款
    --==================================================
    INSERT INTO `G11_1_4.6.H`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN OD_DAY = '180D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.3.H'
                END)
               WHEN OD_DAY = '270D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.4.H'
                END)
               WHEN OD_DAY = '360D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.5.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.5.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.5.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.5.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.5.H'
                END)
               WHEN OD_DAY = '360AD' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.6.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.6.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.6.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.6.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.6.H'
                END)
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT CASE
                       WHEN A.OD_DAYS > 360 THEN
                        '360AD'
                       WHEN A.OD_DAYS IS NULL THEN
                        '360AD' --shiwenbo by 20170313-OD_DAY 增加逾期天数为空的判断，将数据放入一年以上
                       WHEN A.OD_DAYS > 270 THEN
                        '360D'
                       WHEN A.OD_DAYS > 180 THEN
                        '270D'
                       WHEN A.OD_DAYS > 90 THEN
                        '180D'
                       WHEN A.OD_DAYS > 60 THEN
                        '60D' -- 20200114 modify ljp 增加 60天 期限
                       WHEN A.OD_DAYS > 30 THEN
                        '90D'
                       WHEN A.OD_DAYS > 0 THEN
                        '30D'
                     END AS OD_DAY,
                     A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                     A.INT_ADJEST_AMT AS INT_ADJEST_AMT,
                     A.CURR_CD AS CURR_CD,
                     A.OD_FLG AS OD_FLG,
                     A.DATA_DATE AS DATA_DATE,
                     A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                     A.ACCT_STS AS ACCT_STS,
                     A.ORG_NUM AS ORG_NUM,
                     A.ACCT_TYP AS ACCT_TYP
                FROM SMTMODS_L_ACCT_LOAN A
                where A.CANCEL_FLG <> 'Y'
                  AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        ) A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAY IN ('180D', '270D', '360D', '360AD')
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP not LIKE '90%'
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN OD_DAY = '180D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.3.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.3.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.3.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.3.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.3.H'
                   END)
                  WHEN OD_DAY = '270D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.4.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.4.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.4.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.4.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.4.H'
                   END)
                  WHEN OD_DAY = '360D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.5.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.5.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.5.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.5.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.5.H'
                   END)
                  WHEN OD_DAY = '360AD' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.6.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.6.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.6.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.6.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.6.H'
                   END)
                END;

INSERT INTO `G11_1_4.6.H`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    
      --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.6.H' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
        /* and t.p_od_date < t.i_od_date
         and (D_DATADATE_CCY - t.p_od_date + 1) > 360;


-- ========== 逻辑组 21: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN FLAG_TMP = '1' THEN
                'G11_1_4.2.C'
               WHEN FLAG_TMP = '2' THEN
                'G11_1_4.2.D'
               WHEN FLAG_TMP = '3' THEN
                'G11_1_4.2.F'
               WHEN FLAG_TMP = '4' THEN
                'G11_1_4.2.G'
               WHEN FLAG_TMP = '5' THEN
                'G11_1_4.2.H'
             END AS ITEM_NUM, --指标号
             SUM(NVL(LOAN_ACCT_BAL_RMB, 0) + NVL(OD_LOAN_ACCT_BAL_RMB, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_A_REPT_LOAN_BAL_G1101
       WHERE FLAG_TMP IN ('1', '2', '3', '4', '5')
       GROUP BY ORG_NUM,
                CASE
                  WHEN FLAG_TMP = '1' THEN
                   'G11_1_4.2.C'
                  WHEN FLAG_TMP = '2' THEN
                   'G11_1_4.2.D'
                  WHEN FLAG_TMP = '3' THEN
                   'G11_1_4.2.F'
                  WHEN FLAG_TMP = '4' THEN
                   'G11_1_4.2.G'
                  WHEN FLAG_TMP = '5' THEN
                   'G11_1_4.2.H'
                END
) q_21
INSERT INTO `G11_1_4.2.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.2.G` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G11_1_4.2.D` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: G11_1_5.3.D.2024
--5.3减：不再认定为重组贷款  2024年新制度 年初是重组贷款本期不是重组贷款
    INSERT INTO `G11_1_5.3.D.2024`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN C.LOAN_GRADE_CD ='2'  THEN
           'G11_1_5.3.D.2024'
         WHEN C.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.3.F'
         WHEN C.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.3.G'
         WHEN C.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.3.H'
         --20250318 2025年制度升级
         WHEN C.LOAN_GRADE_CD = '1' THEN
          'G11_1_5.3.C.2025'

       END AS ITEM_NUM, --指标号
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) +
       SUM(A.INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN cbrc_TM_CBRC_G1101_TEMP1 C
          ON A.LOAN_NUM = C.LOAN_NUM
          AND A.ORG_NUM = C.ORG_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE RESCHED_FLG = 'N'
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN C.LOAN_GRADE_CD ='2'  THEN
                    'G11_1_5.3.D.2024'
                  WHEN C.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.3.F'
                  WHEN C.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.3.G'
                  WHEN C.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.3.H'
                  WHEN C.LOAN_GRADE_CD = '1' THEN
                   'G11_1_5.3.C.2025'
                END;


