const oObjectFreeze = this.Object.freeze;

Object.freeze = function (obj, ...args) {
  if (!obj?.hasOwnProperty) {
    return oObjectFreeze.call(this, obj, ...args);
  }

  try {
    const theme = %@;

    if (obj.hasOwnProperty?.('BACKGROUND_PRIMARY') || obj.hasOwnProperty?.('BACKGROUND_SECONDARY')) {
      return oObjectFreeze.call(this, Object.assign(obj, theme.spec === 2 
        ? theme.semanticColors ?? theme.theme_color_map
        : theme.theme_color_map), ...args);
    }

    if (obj.hasOwnProperty?.('PRIMARY_100') || obj.hasOwnProperty?.('RED_400')) {
      return oObjectFreeze.call(this, Object.assign(obj, theme.spec === 2
        ? theme.rawColors ?? theme.colours ?? theme.colors
        : theme.colours), ...args);
    }
  } catch (e) {
    console.log(e);
  }

  return oObjectFreeze.apply(this, [obj, ...args]);
};
