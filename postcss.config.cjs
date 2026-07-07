module.exports = {
  plugins: {
    "postcss-preset-env": {
      stage: 2,
      features: {
        // 关键：不要把 CSS 变量内联成默认值回退，否则会把 #f9a8d4 烤死到各处，主题色无法动态生效
        "custom-properties": false,
        // 保留原生 color-mix，不生成基于默认色的写死回退
        "color-mix": false,
      },
    },
    autoprefixer: {},
  },
};
