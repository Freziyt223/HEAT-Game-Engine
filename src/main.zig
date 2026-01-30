const User = @import("User");

pub fn main() !void {
    if (@hasDecl(User, "init")) try User.init();
    defer if (@hasDecl(User, "deinit")) User.deinit();
}