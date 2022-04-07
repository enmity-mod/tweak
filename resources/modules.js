const oldObjectCreate = this.Object.create;
const _window = this;
_window.Object.create = (...args) => {
    const obj = oldObjectCreate.apply(_window.Object, args);
    if (args[0] === null) {
        _window.modules = obj;
        _window.Object.create = oldObjectCreate;
    }
    return obj;
};