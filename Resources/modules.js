const oObjectCreate = this.Object.create;
const win = this;

Object.create = function (...args) {
  const obj = oObjectCreate.apply(this, args);

  if (args[0] === null) {
    win.modules = obj;
    win.Object.create = oObjectCreate;
  }

  return obj;
};