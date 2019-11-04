/*------------------------------------------------------------
Description : Price Calculation to Update PricebookEntry for Articles
Test Class  : None
Author: CGI
------------------------------------------------------------*/
public class ProductService { 
    
    static final Decimal PRICE_FACTOR = 0.5;
    static final Decimal PROPLUS_FACTOR = 40.4;
    
    public static void calculateMassArticlePrices(){
       	
        List<PricebookEntry> productEntryList = new List<PricebookEntry>();
        List<PricebookEntry> listToUpdate = new List<PricebookEntry>(); 
		productEntryList = getPricebookEntries();
        
        for(PricebookEntry singleEntry : productEntryList){
        	Decimal unitPrice = getPrice(singleEntry);
            singleEntry.UnitPrice = unitPrice;
            System.debug('CALCULATED_PRICE_DEBUG: '+ unitPrice);
            listToUpdate.add(singleEntry);
            
            
            //TEMPORARY - ONLY FOR DEMO
            Product2 prodtoupdate = getArticleProduct(singleEntry.Product2Id);
            prodtoupdate.TF_Price__c = unitPrice;
            System.debug('TEST ' + prodtoupdate.TF_Price__c);
            update prodtoupdate;
        }
        Database.update(listToUpdate, false);
        
    }
    
    public static void calculateSingleArticlePrice(PricebookEntry pbe){       	
        Decimal unitPrice = getPrice(pbe);
        pbe.UnitPrice = unitPrice;
        update pbe;        
    }
    
    
    public static Decimal getPrice(PricebookEntry pbe){
       	//( (PONE+FACTOR)*OONE  +  VONE + VTWO  +  FIX/AONE  +  BEFPLUS)  *  PTWO  *  PROPLUS/40,4)
        
        Decimal PTWO = calculatePTWO(pbe.Product2.Total_m2__c);
        System.debug('PTWO: ' + PTWO);
        
        Decimal Supplement = calculateSupplement(pbe.Product2.Total_m2__c);
        System.debug('Supplement: ' + Supplement);
        
        Decimal PONE = Supplement * pbe.Product2.Commercial_Quality__r.Total_w_extra_surcharge__c;
        System.debug('PONE: ' + PONE);
        
        Decimal VTWO = calculateVTWO(pbe.Product2.Print_Surface__c,pbe.Product2.Number_of_colors__c,pbe.Product2.OONE__c);
        System.debug('VTWO: ' + VTWO);
        
        Decimal FIXPLUS = pbe.Product2.FEFCO_Code__r.FIX__c + getFIXPLUS(pbe.Product2.Print_Surface__c,pbe.Product2.Number_of_colors__c);
        System.debug('FIXPLUS: ' + FIXPLUS);
        
        Decimal VONE = calculateVONE(Integer.valueof(pbe.Product2.Commercial_Quality__r.Name),pbe.Product2.OONE__c,pbe.Product2.Height__c,pbe.Product2.Sheet_Lenght__c,pbe.Product2.Sheet_Width__c); 
        System.debug('VONE: '+ VONE);
        
        Decimal price = (
                			(PONE+ PRICE_FACTOR ) * 
                             pbe.Product2.OONE__c  + VONE + VTWO + FIXPLUS / pbe.Product2.AONE__c +  
                             pbe.Product2.BEFPLUS__c
            			) *  PTWO * pbe.Product2.Price_Strategy__r.Factor__c/PROPLUS_FACTOR;    
        
        return price;
        
    }
    
  
    
    public static Product2 getArticleProduct(Id idProd){
        Product2 prod = [SELECT Id, TF_Price__c FROM Product2 WHERE Id =: idProd];
        return prod;		        
    }
    
    public static Decimal calculateVTWO(String surface, String colors, Decimal oone){ 
                
        Decimal vtwo;
        Price_Coefficient__c printFactor = new Price_Coefficient__c ();
        printFactor = [SELECT Id, Value__c FROM Price_Coefficient__c WHERE Type__c = 'Print' AND Number_of_colors__c =: colors AND Print_Surface__c =: surface ];
        System.debug('PRINT FACTOR: ' + printFactor.Value__c);
        //vtwo =  oone * printFactor.Value__c;
        vtwo =  printFactor.Value__c;        
        return vtwo;   
    }
    
    public static Decimal calculateVONE(Integer quality,Decimal oone, Decimal height,  Decimal sheetLength, Decimal sheetWidth){ 
                
        Decimal vone;
        
        if(quality < 600 && sheetLength < 1680 && sheetWidth < 636 ) {
        	//V1=0.56+O1*.44+H*0.0001
            vone = (0.56+(oone*0.44))+(height *0.0001);
        }else if(quality < 600 && (sheetLength >= 1680 || sheetWidth >= 636)){
         	//V1=0.75+O1*.55+H*0.0003
         	vone = (0.75+(oone*0.55))+(height *0.0003); 
        }else if(quality > 599 && sheetLength < 1680 && sheetWidth < 636){
          	//V1=0.65+O1*.52+H*0.0002
          	vone = (0.65+(oone*0.52))+(height *0.0002);
        }else if(quality > 599 && (sheetLength >= 1680 || sheetWidth >= 636)){
            //V1=0.85+O1*.75+H*0.0003
            vone = (0.85+(oone*0.75))+(height *0.0003);
        }
        
        return vone;   
    }
    
    public static Decimal getFIXPLUS(String surface, String colors){ 

        Price_Coefficient__c printFactor = new Price_Coefficient__c ();
        printFactor = [SELECT Id, FIX__c FROM Price_Coefficient__c WHERE Type__c = 'Print' AND Number_of_colors__c =: colors AND Print_Surface__c =: surface ];    
        
        return printFactor.FIX__c;   
    }
    
    public static Decimal calculateSupplement(Decimal total){ 
                
        Decimal supplement;
        Decimal result;
		Decimal order;		
        PONE_Parameters__c poneParamSurchargeIndex = new PONE_Parameters__c ();
        PONE_Parameters__c poneParamSurchargeNextIndex = new PONE_Parameters__c ();
        List<PONE_Parameters__c> poneParamOffcode = new List<PONE_Parameters__c> ();
        
        
        poneParamSurchargeNextIndex = [SELECT Id, Name, Index__c, Order__c, Type__c, Quantity__c FROM PONE_Parameters__c WHERE Type__c = 'SURCHARGE' AND Quantity__c >=: total ORDER BY Quantity__c ASC LIMIT 1];
        order = poneParamSurchargeNextIndex.Order__c - 1;
        poneParamSurchargeIndex = [SELECT Id, Name, Index__c, Order__c, Type__c, Quantity__c FROM PONE_Parameters__c WHERE Type__c = 'SURCHARGE' AND Order__c =: order ];
        
        
        //index - ( index - next index) / (next m2 - m2) * ( m2param - m2 )       
        System.debug('PONE INDEX: ' + JSON.serialize(poneParamSurchargeIndex));
        System.debug('PONE NEXT INDEX: ' + JSON.serialize(poneParamSurchargeNextIndex));
        	
        
        Decimal calc = poneParamSurchargeIndex.Index__c - ( poneParamSurchargeIndex.Index__c - poneParamSurchargeNextIndex.Index__c) / ( poneParamSurchargeNextIndex.Quantity__c - poneParamSurchargeIndex.Quantity__c ) * ( total - poneParamSurchargeIndex.Quantity__c );
		System.debug('PONE CALC: '+ calc); 
        
        poneParamOffcode = [SELECT Id, Name, Index__c, Order__c, Type__c, Quantity__c FROM PONE_Parameters__c WHERE Type__c = 'OFFCODE' ORDER BY Quantity__c ASC];
		System.debug('PONE OFFCODE: ' + JSON.serialize(poneParamOffcode));
        
        result = (calc * poneParamOffcode[0].Index__c);
        System.debug('PONE RESULT: '+result);
        
        return result;  
                 
    }
         
    public static Decimal calculatePTWO(Decimal total){ 
                
        Decimal ptwo;
        if(total  >=0  && total <= 100){
            ptwo = 1.55;
        }else if(total  >=101  && total <= 175){
            ptwo = 1.55;
        }else if(total  >=176  && total <= 375){
            ptwo = 1.50;
        }else if(total  >=376  && total <= 625){
            ptwo = 1.30;
        }else if(total  >=626  && total <= 875){
            ptwo = 1.25;
        }else if(total  >=876 && total <= 1750){
            ptwo = 1.20;
        }else if(total  >=1751  && total <= 3750){
            ptwo = 1.12;
        }else if(total  >=3751  && total <= 7500){
            ptwo = 1.10;
        }else if(total  >=7501 && total <= 15000){
            ptwo = 1.09;
        }else if(total  >=15001  && total <= 35000){
            ptwo = 1.087;
        }else if(total  >=35001 && total <= 75000){
            ptwo = 1.076;
        }else if(total  >=75000){
            ptwo = 1.07;
        }else{
            ptwo = 0;
        }        
        return ptwo;   
    }

    public static List<PricebookEntry> getPricebookEntries(){
        List<PricebookEntry> productEntryList = [
            SELECT Id, 
            Pricebook2Id, 
            Product2Id, 
            Product2.Name, 
            Product2.Closure__c,
            Product2.Diecut__c,
            Product2.Family,
            Product2.FEFCO_Code__c,
            Product2.Has_Certificate__c,
            Product2.Height__c,            
            Product2.IsActive,
            Product2.Length__c,
            Product2.Number_of_colors__c,
            Product2.Parts__c,
            Product2.Patte__c,
            Product2.Print_Surface__c,
            Product2.ProductCode,
            Product2.RecordTypeId,
            Product2.Reference_Number__c,
            Product2.Sheet_Lenght__c,
            Product2.Sheet_Width__c,
            Product2.Type__c,
            Product2.Width__c,
            Product2.VONE__c,
            Product2.VTWO__c,
            Product2.OONE__c,
            Product2.FIX__c,
            Product2.PONE__c,
            Product2.PTWO__c,
            Product2.PROPLUS__c,
            Product2.BEFPLUS__c,
            Product2.AONE__c,            
            Product2.Total_m2__c,
            Product2.OFFCODE_PERC__c,
            Product2.Commercial_Quality__r.Name,
            Product2.Price_Strategy__r.Factor__c,
            Product2.Commercial_Quality__r.Total_w_extra_surcharge__c,
            Product2.FEFCO_Code__r.FIX__c
            
            
            FROM PricebookEntry 
            WHERE Product2.Family = 'Article'
        	AND Product2.Name = 'ARTICLE 0002 - 11'];
        return productEntryList;
        
    }
    
}