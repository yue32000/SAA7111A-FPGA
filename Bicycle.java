package bike;

public class Bicycle {
	// the Bicycle class has three fields
    public int cadence;
    public int gear;
    public int speed;
    private int speed2gear = 2;
        
    // the Bicycle class has one constructor
    public Bicycle(int startCadence, int startSpeed, int startGear) {
        gear = startGear;
        cadence = startCadence;
        speed = startSpeed;
    }
        
    // the Bicycle class has four methods
    public void setCadence(int newValue) {
        cadence = newValue;
    }
        
    public void setGear(int newValue) {
        gear = newValue;
    }
        
    public void applyBrake(int decrement) {
        speed -= decrement;
        changeGear(-decrement/speed2gear);
    }
        
    public void speedUp(int increment) {
        speed += increment;
        changeGear(increment/speed2gear);
    }
    
    // increase speed with high gear
    private void changeGear(double factor){
    	int factorInt = (int)factor;
    	gear += factorInt;
    }
    
    // accessor for private variable
    // integer return type
    public int getFactor(){
    	return speed2gear;
    }
}
