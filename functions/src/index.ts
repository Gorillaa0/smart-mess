import * as admin from 'firebase-admin';

admin.initializeApp();

export * from './auth/createStudent';
export * from './auth/createManager';
export * from './auth/importStudentsCSV';
export * from './auth/setUserStatus';

export * from './meals/createMeal';
export * from './meals/generateQR';
export * from './meals/verifyQR';

export * from './messoff/markMessOff';
export * from './messoff/cancelMessOff';

export * from './prediction/triggerPrediction';
export * from './prediction/approvePrediction';

export * from './wastage/enterWastage';

export * from './billing/calculateBilling';

export * from './notifications/onComplaintUpdated';
export * from './notifications/scheduledReminders';

export * from './seed/seedData';
