const oObjectCreate = this.Object.create;
const win = this;

Object.create = (...args) => {
  const obj = oObjectCreate.apply(_window.Object, args);

  if (args[0] === null) {
    win.modules = obj;
    win.Object.create = oObjectCreate;
  }

  return obj;
};