/**********************************************************
This is example code for using the Adafruit liquid flow meters. 

Tested and works great with the Adafruit plastic and brass meters
    ------> http://www.adafruit.com/products/828
    ------> http://www.adafruit.com/products/833

Connect the red wire to +5V, 
the black wire to common ground 
and the yellow sensor wire to pin #2

Adafruit invests time and resources providing this open source code, 
please support Adafruit and open-source hardware by purchasing 
products from Adafruit!

Written by Limor Fried/Ladyada  for Adafruit Industries.  
BSD license, check license.txt for more information
All text above must be included in any redistribution
**********************************************************/
#include "LiquidCrystal.h"
LiquidCrystal lcd(7, 8, 9, 10, 11, 12);

// which pin to use for reading the sensor? can use any pin!

# define LED_AMARELO A1


# define LED_VERDE    A2


# define APAGADO LOW

# define ACESO    HIGH


# define BUZZER 5


# define SENSOR_MIN 7


# define SENSOR_MAX 8



# define BOMBA 9


# define LIGADA LOW


# define DESLIGADA HIGH


// Estados do reservatório


# define VAZIO 0

# define INTERMEDIÁRIO 1

# define CHEIO 2

# define DEFEITO 3

char não assinado novo ( unsigned char novo_estado);

// indica transição de estado do reservatório

transicao booleano = verdadeiro ;

// estado do reservatorio

sem assinatura int reservatorio = novo (VAZIO);

// funçao de setup apenas 1 vez na inicialização do programa.

#define FLOWSENSORPIN 2

// count how many pulses!
volatile uint16_t pulses = 0;
// track the state of the pulse pin
volatile uint8_t lastflowpinstate;
// you can try to keep time of how long it is between pulses
volatile uint32_t lastflowratetimer = 0;
// and use that to calculate a flow rate
volatile float flowrate;
// Interrupt is called once a millisecond, looks for any pulses from the sensor!
SIGNAL(TIMER0_COMPA_vect) {
  uint8_t x = digitalRead(FLOWSENSORPIN);
  
  if (x == lastflowpinstate) {
    lastflowratetimer++;
    return; // nothing changed!
  }
  
  if (x == HIGH) {
    //low to high transition!
    pulses++;
  }
  lastflowpinstate = x;
  flowrate = 1000.0;
  flowrate /= lastflowratetimer;  // in hertz
  lastflowratetimer = 0;
}

void useInterrupt(boolean v) {
  if (v) {
    // Timer0 is already used for millis() - we'll just interrupt somewhere
    // in the middle and call the "Compare A" function above
    OCR0A = 0xAF;
    TIMSK0 |= _BV(OCIE0A);
  } else {
    // do not call the interrupt function COMPA anymore
    TIMSK0 &= ~_BV(OCIE0A);
  }
}

void setup() {


 // inicializa os led sinalizadores
 pinMode (LED_VERDE, OUTPUT);
 pinMode (LED_AMARELO, OUTPUT);


 // inicializa o pino da bomba como saída
 pinMode (BOMBA, OUTPUT);


 // liga os resistores de puxar dos pinos dos sensores
 pinMode (SENSOR_MAX, INPUT_PULLUP);
 pinMode (SENSOR_MIN, INPUT_PULLUP);  

// função que continuamente se inicia na inicialização do programa.

   Serial.begin(9600);
   Serial.print("Flow sensor test!");
   lcd.begin(16, 2);
// função do sensor de fluxo   
   
   pinMode(FLOWSENSORPIN, INPUT);
   digitalWrite(FLOWSENSORPIN, HIGH);
   lastflowpinstate = digitalRead(FLOWSENSORPIN);
   useInterrupt(true);
}

void loop()                     // run over and over again
{ 

 // o ósquio máximo e mínimo continuamente
 boolean min, max;
 min = sensor_min ();
 max = sensor_max (); 



 // aciona os leds indicativos de cada um dos sensores
 led_amarelo (! min);
 led_verde (! max);  



 // monitora o estado de defeito
 if(!max && min){
   reservatorio = novo(DEFEITO);       
 }

 // trata cada um dos estados do reservatório!
 switch(reservatorio){
   case VAZIO:
     if(houve_transicao()){
       bomba(LIGADA);
     }         
     if(min){
       reservatorio = novo(INTERMEDIARIO);
     }   
   break;
  
   case INTERMEDIARIO:
     if(houve_transicao()){
       // nada muda ao entrar ou sair deste estado
     }
     if(max){
       reservatorio = novo(CHEIO);
     }             
     if(!min){
       reservatorio = novo(VAZIO);
     }            
   break;
  
   case CHEIO:
     if(houve_transicao()){
       bomba(DESLIGADA);
     }
     if(!max){
       reservatorio = novo(INTERMEDIARIO);
     }                 
   break;
  
   case DEFEITO:   
     if(houve_transicao()){
       bomba(DESLIGADA);       
       buzzer(50);
     }
     if(max && min){
       reservatorio = novo(VAZIO);
       buzzer(0);                 
     }
   break;
 }   
}

unsigned char houve_transicao(){
 if(transicao){
   transicao = false;
   return true;
 }
 return false;
}

unsigned char novo(unsigned char novo_estado){
 transicao = true;
 return novo_estado;
}

// liga o buzzer
void buzzer(unsigned char pwm){
 analogWrite(BUZZER, pwm); 
}

// acende ou apaga o led amarelo
void led_amarelo(boolean estado){
 digitalWrite(LED_AMARELO, estado);
}

// acende ou apaga o led verde
void led_verde (boolean estado) {
 digitalWrite (LED_VERDE, estado);
}

// lê uma posição do sensor de níve máximo
booleano sensor_max () {
 retorno ( digitalRead (SENSOR_MAX) == BAIXO);
}

// lê uma posição do sensor de níve mínimo
booleano sensor_min () {
 return ( digitalRead (SENSOR_MIN) == BAIXO);
}

// aciona uma bomba que enche o reservatório
void bomba (boolean estado) {
   digitalWrite (BOMBA, estado);
}

// informa se houve transição de estado e ajusta a variavel de transicao

  lcd.setCursor(0, 0);
  lcd.print("Pulses:"); lcd.print(pulses, DEC);
  lcd.print(" Hz:");
  lcd.print(flowrate);
  //lcd.print(flowrate);
  Serial.print("Freq: "); Serial.println(flowrate);
  Serial.print("Pulses: "); Serial.println(pulses, DEC);
  
  // if a plastic sensor use the following calculation
  // Sensor Frequency (Hz) = 7.5 * Q (Liters/min)
  // Liters = Q * time elapsed (seconds) / 60 (seconds/minute)
  // Liters = (Frequency (Pulses/second) / 7.5) * time elapsed (seconds) / 60
  // Liters = Pulses / (7.5 * 60)
  float liters = pulses;
  liters /= 7.5;
  liters /= 60.0;

/*
  // if a brass sensor use the following calculation
  float liters = pulses;
  liters /= 8.1;
  liters -= 6;
  liters /= 60.0;
*/
  Serial.print(liters); Serial.println(" Liters");
  lcd.setCursor(0, 1);
  lcd.print(liters); lcd.print(" Liters        ");
 
  delay(100);
}
