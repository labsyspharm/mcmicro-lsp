Channel.fromPath("**/*.{rcpnl,pysed.ome.tif}").map{ it ->
  dir = it.getBaseName().split('@').head();
  file("raw/$dir").mkdirs();
  println("$it.name -> raw/$dir/$it.name");
  it.moveTo("raw/$dir");
  if (it.parent.toFile().delete()) {
    println("deleting empty directory: $it.parent");
  }
}
