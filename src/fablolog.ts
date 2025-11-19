export function printSplash() {
  const darkGray = '\x1b[90m';
  const end = '\x1b[0m';
  console.log("");
  const monthDay = new Date().getMonth() * 100 + new Date().getDate();
  if (monthDay > 1215) {
    console.log("┌──────       *        ┌─────.    ╷           .────.");
    console.log("│           _/_\\_      │      │   │         ╱        ╲ ");
    console.log("├─────     _/___\\_     ├─────:    │        │          │");
    console.log("│         _/_____\\_    │      │   │         ╲        ╱ ");
    console.log(`╵            |_|       └─────'    └──────     '────'    v${process.env.FABLO_VERSION || ''}`.padEnd(80));
  } else {
    console.log("┌──────      .─.       ┌─────.    ╷           .────.");
    console.log("│           /   \\      │      │   │         ╱        ╲ ");
    console.log("├─────     /     \\     ├─────:    │        │          │");
    console.log("│         /───────\\    │      │   │         ╲        ╱ ");
    console.log(`╵        /         \\   └─────'    └──────     '────'    v${process.env.FABLO_VERSION || ''}`.padEnd(80));
  }
  console.log(`${darkGray}┌┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┐`);
  console.log("│ https://fablo.io | created at SoftwareMill | backed by Hyperledger Foundation│");
  console.log(`└┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘${end}`);
}



