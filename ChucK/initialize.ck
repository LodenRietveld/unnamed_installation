public class F {
	fun static string file(string name){
		return me.dir() + "/" + name;
	}

	fun static void load(string name){
		Machine.add(F.file(name));
	}
}


//VERY LOUD BE CAREFUL


F.load("StringFunc.ck");
F.load("Float.ck");
F.load("Vector.ck");
F.load("Slide.ck");
F.load("OscData.ck");

F.load("FloatListAssoc.ck");
F.load("NoteMaterialGenerator.ck");

F.load("ParameterCurve.ck");
F.load("ParabolicCurve.ck");

F.load("GenerationalDataPoint.ck");
F.load("GenerationalMetaData.ck");
F.load("GenerationalData.ck");
F.load("Lock.ck");
F.load("start.ck");


//VERY LOUD BE CAREFUL
