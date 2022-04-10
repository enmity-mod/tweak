const oObjectFreeze = this.Object.freeze;
Object.freeze = function(obj, ...args) {
  if (!obj?.hasOwnProperty) { 
    return oObjectFreeze.apply(this, [obj, ...args])
  }
  try { 
    const theme = %@;

    if (obj.hasOwnProperty?.('BACKGROUND_PRIMARY')) {
      return oObjectFreeze.apply(this, [{
        ...obj,
        ...theme.theme_color_map
      }, ...args]);
    }

    if (obj.hasOwnProperty?.('PRIMARY_DARK')) {
      return oObjectFreeze.apply(this, [{
        ...obj,
        ...theme.colours
      }, ...args]);
    }

    if (obj.hasOwnProperty?.('CHAT_GREY')) {
      if (themes?.colours?.PRIMARY_DARK_630) {
        return oObjectFreeze.apply(this, [{
          ...obj,
          'CHAT_GREY': theme.colours.PRIMARY_DARK_630,
        }, ...args]);
      } else {
        return oObjectFreeze.apply(this, [obj, ...args]);
      }
    }
  } catch(e) {
    console.log(e);
  }

  return oObjectFreeze.apply(this, [obj, ...args]);
}
