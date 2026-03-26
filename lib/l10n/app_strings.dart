import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';

class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  static AppStrings of(BuildContext context) {
    final code = context.watch<LocaleProvider>().languageCode;
    return AppStrings(code);
  }

  static AppStrings read(BuildContext context) {
    final code = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    return AppStrings(code);
  }

  static const _values = <String, Map<String, String>>{
    'en': {
      'familyCalendar': 'Family Calendar',
      'calendar': 'Calendar',
      'agenda': 'Agenda',
      'todo': 'To-Do',
      'settings': 'Settings',
      'familyMembers': 'Family Members',
      'categories': 'Event Categories',
      'appSettings': 'App Settings',
      'theme': 'Theme',
      'language': 'Language',
      'account': 'Account',
      'about': 'About',
      'signOut': 'Sign Out',
      'english': 'English',
      'spanish': 'Spanish',
      'hindi': 'Hindi',
      'shopping': 'Shopping',
      'tasks': 'Tasks',
      'quickAdd': 'Quick Add',
      'recentItems': 'Recent Items',
      'addItem': 'Add Item',
      'changeName': 'Change Name',
      'addPhoto': 'Select Profile Image',
      'chooseTheme': 'Choose Theme',
      'themeSaved': 'Your selection is saved to your profile and restored every time you sign in.',
      'chooseLanguage': 'Choose how labels appear across the app.',
      'notLoggedIn': 'Not logged in',
      'editDisplayName': 'Edit Display Name',
      'displayName': 'Display name',
      'cancel': 'Cancel',
      'save': 'Save',
      'create': 'Create',
      'close': 'Close',
      'profilePhotoUpdated': 'Profile photo updated',
      'displayNameUpdated': 'Display name updated',
      'pleaseEnterDisplayName': 'Please enter a display name',
      'unableToSelectImage': 'Unable to select image',
      'selectProfileImage': 'Select Profile Image',
      'chooseFromApp': 'Choose one of the bundled characters below.',
      'useThisPhoto': 'Use This Photo',
      'familyTaskLists': 'Family Task Lists',
      'myTaskLists': 'My Task Lists',
      'taskWorkspaceSubtitle': 'Keep plans, assignments, and follow-ups in one place.',
      'shoppingWorkspaceSubtitle': 'Shared lists for groceries, travel, gifts, and all the little plans in between.',
      'workspace': 'Workspace',
      'scope': 'Scope',
      'view': 'View',
      'myLists': 'My Lists',
      'compact': 'Compact',
      'detailed': 'Detailed',
      'newList': 'New List',
      'searchLists': 'Search Lists',
      'defaultShoppingLists': 'Default family lists are ready to use.',
      'joinFamilyShopping': 'Join a family to use shared shopping',
      'shoppingNeedsFamily': 'Shopping lists sync across family members and work best from a shared family space.',
      'openList': 'Open list',
      'listDetails': 'List Details',
      'addAnotherItem': 'Add another item',
      'noItemsYet': 'No items yet',
      'addFirstItem': 'Add your first item to get this list started.',
      'groceryList': 'Grocery List',
      'packingList': 'Packing List',
      'giftIdeas': 'Gift Ideas',
      'houseProjects': 'House Projects',
      'moviesToWatch': 'Movies to Watch',
      'tripIdeas': 'Trip Ideas',
      'others': 'Others',
      'itemName': 'Item name',
      'quantity': 'Quantity',
      'category': 'Category',
      'aisle': 'Aisle',
      'note': 'Note',
      'searchGroceryItems': 'Search grocery items',
      'typeCustomItem': 'Type a custom item if it is not listed.',
      'aboutTitle': 'About Family Calendar',
      'aboutBody': 'Family Calendar v1.0.0\n\nA colorful family calendar that makes planning easy for everyone. Share events, reminders, and activities in one fun place.',
      'signOutTitle': 'Sign Out',
      'signOutPrompt': 'Are you sure you want to sign out?',
      'showBundledAvatars': 'Select Profile Image',
      'usePhotoFromApp': 'Or choose one from the app',
      'shoppingItemsCountOne': '1 item',
      'shoppingItemsCountMany': '{count} items',
      'activeItemsOne': '1 active item',
      'activeItemsMany': '{count} active items',
      'enterItem': 'Enter an item',
      'chooseListName': 'List name',
      'customAisles': 'Custom aisles',
      'editItem': 'Edit Item',
      'addItemTitle': 'Add Item',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'shoppingListStyleHint': 'Tap a list to manage items on a dedicated screen.',
      'languageUpdated': 'Language updated',
      'shareWithFamily': 'Share with Family',
      'privateList': 'Private',
      'sharedList': 'Shared',
      'deleteList': 'Delete List',
      'makePrivate': 'Make Private',
      'reorderHint': 'Press and drag to reorder',
      'events': 'Events',
      'calendarView': 'Calendar View',
      'openCalendar': 'Open Calendar',
      'loggedIn': 'Logged In',
      'configuration': 'Configuration',
      'agendaDescription': 'Shows events due today or in the future. To view past events, check Calendar view.',
      'noUpcomingEvents': 'No upcoming events',
      'createListTitle': 'Create List',
      'editListTitle': 'Edit List',
      'listName': 'List Name',
      'descriptionLabel': 'Description',
      'enterListNamePrompt': 'Please enter a list name',
      'addTaskTitle': 'Add Task',
      'editTaskTitle': 'Edit Task',
      'taskName': 'Task Name',
      'notesLabel': 'Notes',
      'enterTaskNamePrompt': 'Please enter a task name',
      'noDueDate': 'No Due Date',
      'statusLabel': 'Status',
      'priorityLabelText': 'Priority',
      'assignToFamilyMembers': 'Assign to family members',
      'taskStatusTodo': 'To-Do',
      'taskStatusInProgress': 'In Progress',
      'taskStatusBlocked': 'Blocked',
      'taskStatusCompleted': 'Completed',
      'priorityHigh': 'High',
      'priorityMedium': 'Medium',
      'priorityLow': 'Low',
      'openOfTotal': '{open} open of {total}',
      'createEvent': 'Create Event',
      'addEvent': 'Add Event',
      'editEvent': 'Edit Event',
      'eventTitle': 'Event Title',
      'allDay': 'All Day',
      'startTime': 'Start Time',
      'endTime': 'End Time',
      'repeat': 'Repeat',
      'repeatOn': 'Repeat on',
      'doesNotRepeat': 'Does not repeat',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'noRecurrenceEndDate': 'No recurrence end date',
      'repeatUntil': 'Repeat until {date}',
      'clearRecurrenceEndDate': 'Clear recurrence end date',
      'eventIcon': 'Event Icon',
      'chooseEventIcon': 'Choose Event Icon',
      'chooseEventIconHint': 'Choose a small icon from your event icon library',
      'none': 'None',
      'location': 'Location',
      'saveEvent': 'Save Event',
      'saveChanges': 'Save Changes',
      'selectCategory': 'Select Category',
      'noCategoriesAvailable': 'No categories available',
      'pleaseEnterEventTitle': 'Please enter event title',
      'pleaseSelectCategory': 'Please select a category',
      'endDateBeforeStartDate': 'End date cannot be before start date',
      'endTimeBeforeStartTime': 'End time must be after start time',
      'recurrenceEndBeforeEventDate': 'Recurrence end date cannot be before the event date',
      'selectWeeklyRecurrenceDay': 'Select at least one weekday for weekly recurrence',
      'eventUpdatedSuccessfully': 'Event updated successfully',
      'eventAddedSuccessfully': 'Event added successfully',
      'spansDays': 'Spans {count} days',
    },
    'es': {
      'familyCalendar': 'Calendario Familiar',
      'calendar': 'Calendario',
      'agenda': 'Agenda',
      'todo': 'Tareas',
      'settings': 'Configuracion',
      'familyMembers': 'Miembros de la familia',
      'categories': 'Categorias de eventos',
      'appSettings': 'Configuracion de la app',
      'theme': 'Tema',
      'language': 'Idioma',
      'account': 'Cuenta',
      'about': 'Acerca de',
      'signOut': 'Cerrar sesion',
      'english': 'Ingles',
      'spanish': 'Espanol',
      'hindi': 'Hindi',
      'shopping': 'Compras',
      'tasks': 'Tareas',
      'quickAdd': 'Agregar rapido',
      'recentItems': 'Recientes',
      'addItem': 'Agregar articulo',
      'changeName': 'Cambiar nombre',
      'addPhoto': 'Seleccionar imagen de perfil',
      'chooseTheme': 'Elegir tema',
      'themeSaved': 'Tu seleccion se guarda en tu perfil y se restaura cada vez que inicias sesion.',
      'chooseLanguage': 'Elige como aparecen las etiquetas en la aplicacion.',
      'notLoggedIn': 'Sesion no iniciada',
      'editDisplayName': 'Editar nombre visible',
      'displayName': 'Nombre visible',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'create': 'Crear',
      'close': 'Cerrar',
      'profilePhotoUpdated': 'Foto de perfil actualizada',
      'displayNameUpdated': 'Nombre actualizado',
      'pleaseEnterDisplayName': 'Ingresa un nombre visible',
      'unableToSelectImage': 'No se pudo seleccionar la imagen',
      'selectProfileImage': 'Seleccionar imagen de perfil',
      'chooseFromApp': 'Elige uno de los personajes incluidos en la app.',
      'useThisPhoto': 'Usar esta foto',
      'familyTaskLists': 'Listas familiares',
      'myTaskLists': 'Mis listas',
      'taskWorkspaceSubtitle': 'Mantiene planes, responsables y seguimientos en un solo lugar.',
      'shoppingWorkspaceSubtitle': 'Listas compartidas para compras, viajes, regalos y planes cotidianos.',
      'workspace': 'Espacio',
      'scope': 'Alcance',
      'view': 'Vista',
      'myLists': 'Mis listas',
      'compact': 'Compacta',
      'detailed': 'Detallada',
      'newList': 'Nueva lista',
      'searchLists': 'Buscar listas',
      'defaultShoppingLists': 'Las listas familiares predeterminadas estan listas para usar.',
      'joinFamilyShopping': 'Unete a una familia para usar compras compartidas',
      'shoppingNeedsFamily': 'Las listas de compras se sincronizan entre familiares y funcionan mejor en un espacio compartido.',
      'openList': 'Abrir lista',
      'listDetails': 'Detalles de la lista',
      'addAnotherItem': 'Agregar otro articulo',
      'noItemsYet': 'Todavia no hay articulos',
      'addFirstItem': 'Agrega el primer articulo para comenzar esta lista.',
      'groceryList': 'Lista del supermercado',
      'packingList': 'Lista de viaje',
      'giftIdeas': 'Ideas de regalos',
      'houseProjects': 'Proyectos del hogar',
      'moviesToWatch': 'Peliculas para ver',
      'tripIdeas': 'Ideas de viaje',
      'others': 'Otros',
      'itemName': 'Nombre del articulo',
      'quantity': 'Cantidad',
      'category': 'Categoria',
      'aisle': 'Pasillo',
      'note': 'Nota',
      'searchGroceryItems': 'Buscar articulos de supermercado',
      'typeCustomItem': 'Escribe un articulo personalizado si no aparece.',
      'aboutTitle': 'Acerca de Family Calendar',
      'aboutBody': 'Family Calendar v1.0.0\n\nUn calendario familiar colorido que facilita la planificacion para todos. Comparte eventos, recordatorios y actividades en un solo lugar.',
      'signOutTitle': 'Cerrar sesion',
      'signOutPrompt': 'Seguro que deseas cerrar sesion?',
      'showBundledAvatars': 'Seleccionar imagen de perfil',
      'usePhotoFromApp': 'O elige una imagen de la app',
      'shoppingItemsCountOne': '1 articulo',
      'shoppingItemsCountMany': '{count} articulos',
      'activeItemsOne': '1 articulo activo',
      'activeItemsMany': '{count} articulos activos',
      'enterItem': 'Ingresa un articulo',
      'chooseListName': 'Nombre de la lista',
      'customAisles': 'Pasillos personalizados',
      'editItem': 'Editar articulo',
      'addItemTitle': 'Agregar articulo',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Agregar',
      'shoppingListStyleHint': 'Toca una lista para administrar sus articulos en una pantalla dedicada.',
      'languageUpdated': 'Idioma actualizado',
      'shareWithFamily': 'Compartir con la familia',
      'privateList': 'Privada',
      'sharedList': 'Compartida',
      'deleteList': 'Eliminar lista',
      'makePrivate': 'Hacer privada',
      'reorderHint': 'Mantener y arrastrar para reordenar',
      'events': 'Eventos',
      'calendarView': 'Vista del calendario',
      'openCalendar': 'Abrir calendario',
      'loggedIn': 'Sesion iniciada',
      'configuration': 'Configuracion',
      'agendaDescription': 'Muestra eventos para hoy o proximos. Para ver eventos pasados, revisa la vista de calendario.',
      'noUpcomingEvents': 'No hay eventos proximos',
      'createListTitle': 'Crear lista',
      'editListTitle': 'Editar lista',
      'listName': 'Nombre de la lista',
      'descriptionLabel': 'Descripcion',
      'enterListNamePrompt': 'Ingresa un nombre de lista',
      'addTaskTitle': 'Agregar tarea',
      'editTaskTitle': 'Editar tarea',
      'taskName': 'Nombre de la tarea',
      'notesLabel': 'Notas',
      'enterTaskNamePrompt': 'Ingresa un nombre de tarea',
      'noDueDate': 'Sin fecha limite',
      'statusLabel': 'Estado',
      'priorityLabelText': 'Prioridad',
      'assignToFamilyMembers': 'Asignar a familiares',
      'taskStatusTodo': 'Por hacer',
      'taskStatusInProgress': 'En progreso',
      'taskStatusBlocked': 'Bloqueada',
      'taskStatusCompleted': 'Completada',
      'priorityHigh': 'Alta',
      'priorityMedium': 'Media',
      'priorityLow': 'Baja',
      'openOfTotal': '{open} abiertas de {total}',
      'createEvent': 'Crear evento',
      'addEvent': 'Agregar evento',
      'editEvent': 'Editar evento',
      'eventTitle': 'Titulo del evento',
      'allDay': 'Todo el dia',
      'startTime': 'Hora de inicio',
      'endTime': 'Hora de finalizacion',
      'repeat': 'Repetir',
      'repeatOn': 'Repetir en',
      'doesNotRepeat': 'No se repite',
      'daily': 'Diario',
      'weekly': 'Semanal',
      'monthly': 'Mensual',
      'yearly': 'Anual',
      'noRecurrenceEndDate': 'Sin fecha final de repeticion',
      'repeatUntil': 'Repetir hasta {date}',
      'clearRecurrenceEndDate': 'Quitar fecha final de repeticion',
      'eventIcon': 'Icono del evento',
      'chooseEventIcon': 'Elegir icono del evento',
      'chooseEventIconHint': 'Elige un icono pequeno de tu biblioteca de iconos',
      'none': 'Ninguno',
      'location': 'Ubicacion',
      'saveEvent': 'Guardar evento',
      'saveChanges': 'Guardar cambios',
      'selectCategory': 'Seleccionar categoria',
      'noCategoriesAvailable': 'No hay categorias disponibles',
      'pleaseEnterEventTitle': 'Ingresa el titulo del evento',
      'pleaseSelectCategory': 'Selecciona una categoria',
      'endDateBeforeStartDate': 'La fecha final no puede ser anterior a la fecha inicial',
      'endTimeBeforeStartTime': 'La hora final debe ser posterior a la hora inicial',
      'recurrenceEndBeforeEventDate': 'La fecha final de repeticion no puede ser anterior a la fecha del evento',
      'selectWeeklyRecurrenceDay': 'Selecciona al menos un dia para la repeticion semanal',
      'eventUpdatedSuccessfully': 'Evento actualizado correctamente',
      'eventAddedSuccessfully': 'Evento agregado correctamente',
      'spansDays': 'Dura {count} dias',
    },
    'hi': {
      'familyCalendar': 'फैमिली कैलेंडर',
      'calendar': 'कैलेंडर',
      'agenda': 'एजेंडा',
      'todo': 'टू-डू',
      'settings': 'सेटिंग्स',
      'familyMembers': 'परिवार के सदस्य',
      'categories': 'इवेंट श्रेणियां',
      'appSettings': 'ऐप सेटिंग्स',
      'theme': 'थीम',
      'language': 'भाषा',
      'account': 'अकाउंट',
      'about': 'ऐप के बारे में',
      'signOut': 'साइन आउट',
      'english': 'अंग्रेजी',
      'spanish': 'स्पेनिश',
      'hindi': 'हिंदी',
      'shopping': 'शॉपिंग',
      'tasks': 'काम',
      'quickAdd': 'जल्दी जोड़ें',
      'recentItems': 'हाल के आइटम',
      'addItem': 'आइटम जोड़ें',
      'changeName': 'नाम बदलें',
      'addPhoto': 'प्रोफाइल चित्र चुनें',
      'chooseTheme': 'थीम चुनें',
      'themeSaved': 'आपकी पसंद प्रोफाइल में सेव रहेगी और हर साइन-इन पर वापस लागू होगी।',
      'chooseLanguage': 'ऐप में दिखने वाले लेबल की भाषा चुनें।',
      'notLoggedIn': 'लॉग इन नहीं है',
      'editDisplayName': 'डिस्प्ले नाम बदलें',
      'displayName': 'डिस्प्ले नाम',
      'cancel': 'रद्द करें',
      'save': 'सेव करें',
      'create': 'बनाएं',
      'close': 'बंद करें',
      'profilePhotoUpdated': 'प्रोफाइल फोटो अपडेट हो गई',
      'displayNameUpdated': 'डिस्प्ले नाम अपडेट हो गया',
      'pleaseEnterDisplayName': 'डिस्प्ले नाम दर्ज करें',
      'unableToSelectImage': 'चित्र चुनना संभव नहीं हुआ',
      'selectProfileImage': 'प्रोफाइल चित्र चुनें',
      'chooseFromApp': 'ऐप में दिए गए पात्रों में से एक चुनें।',
      'useThisPhoto': 'यह फोटो उपयोग करें',
      'familyTaskLists': 'परिवार की सूचियां',
      'myTaskLists': 'मेरी सूचियां',
      'taskWorkspaceSubtitle': 'योजनाएं, जिम्मेदारियां और फॉलो-अप एक ही जगह रखें।',
      'shoppingWorkspaceSubtitle': 'किराना, यात्रा, उपहार और रोज़मर्रा की योजनाओं के लिए साझा सूचियां।',
      'workspace': 'वर्कस्पेस',
      'scope': 'दायरा',
      'view': 'व्यू',
      'myLists': 'मेरी सूचियां',
      'compact': 'कॉम्पैक्ट',
      'detailed': 'विस्तृत',
      'newList': 'नई सूची',
      'searchLists': 'सूचियां खोजें',
      'defaultShoppingLists': 'डिफॉल्ट परिवार सूचियां उपयोग के लिए तैयार हैं।',
      'joinFamilyShopping': 'साझा शॉपिंग के लिए परिवार से जुड़ें',
      'shoppingNeedsFamily': 'शॉपिंग सूचियां परिवार के सदस्यों के बीच सिंक होती हैं और साझा स्पेस में बेहतर काम करती हैं।',
      'openList': 'सूची खोलें',
      'listDetails': 'सूची विवरण',
      'addAnotherItem': 'एक और आइटम जोड़ें',
      'noItemsYet': 'अभी कोई आइटम नहीं है',
      'addFirstItem': 'इस सूची को शुरू करने के लिए पहला आइटम जोड़ें।',
      'groceryList': 'किराना सूची',
      'packingList': 'पैकिंग सूची',
      'giftIdeas': 'उपहार आइडिया',
      'houseProjects': 'घर के प्रोजेक्ट',
      'moviesToWatch': 'देखने वाली फिल्में',
      'tripIdeas': 'यात्रा आइडिया',
      'others': 'अन्य',
      'itemName': 'आइटम नाम',
      'quantity': 'मात्रा',
      'category': 'श्रेणी',
      'aisle': 'गलियारा',
      'note': 'नोट',
      'searchGroceryItems': 'किराना आइटम खोजें',
      'typeCustomItem': 'अगर सूची में न हो तो अपना कस्टम आइटम लिखें।',
      'aboutTitle': 'Family Calendar के बारे में',
      'aboutBody': 'Family Calendar v1.0.0\n\nएक रंगीन परिवार कैलेंडर जो सबके लिए योजना बनाना आसान करता है। इवेंट, रिमाइंडर और गतिविधियां एक ही जगह साझा करें।',
      'signOutTitle': 'साइन आउट',
      'signOutPrompt': 'क्या आप वाकई साइन आउट करना चाहते हैं?',
      'showBundledAvatars': 'प्रोफाइल चित्र चुनें',
      'usePhotoFromApp': 'या ऐप से कोई चित्र चुनें',
      'shoppingItemsCountOne': '1 आइटम',
      'shoppingItemsCountMany': '{count} आइटम',
      'activeItemsOne': '1 सक्रिय आइटम',
      'activeItemsMany': '{count} सक्रिय आइटम',
      'enterItem': 'आइटम दर्ज करें',
      'chooseListName': 'सूची का नाम',
      'customAisles': 'कस्टम गलियारे',
      'editItem': 'आइटम संपादित करें',
      'addItemTitle': 'आइटम जोड़ें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'add': 'जोड़ें',
      'shoppingListStyleHint': 'आइटम संभालने के लिए किसी सूची को अलग स्क्रीन पर खोलें।',
      'languageUpdated': 'भाषा अपडेट हो गई',
      'shareWithFamily': 'परिवार के साथ साझा करें',
      'privateList': 'निजी',
      'sharedList': 'साझा',
      'deleteList': 'सूची हटाएं',
      'makePrivate': 'निजी बनाएं',
      'reorderHint': 'क्रम बदलने के लिए दबाकर खींचें',
      'events': 'इवेंट्स',
      'calendarView': 'कैलेंडर व्यू',
      'openCalendar': 'कैलेंडर खोलें',
      'loggedIn': 'लॉग्ड इन',
      'configuration': 'कॉन्फ़िगरेशन',
      'agendaDescription': 'आज या आने वाले इवेंट्स यहां दिखते हैं। पुराने इवेंट्स के लिए कैलेंडर व्यू देखें।',
      'noUpcomingEvents': 'कोई आने वाला इवेंट नहीं',
      'createListTitle': 'लिस्ट बनाएं',
      'editListTitle': 'लिस्ट संपादित करें',
      'listName': 'लिस्ट नाम',
      'descriptionLabel': 'विवरण',
      'enterListNamePrompt': 'कृपया लिस्ट नाम दर्ज करें',
      'addTaskTitle': 'टास्क जोड़ें',
      'editTaskTitle': 'टास्क संपादित करें',
      'taskName': 'टास्क नाम',
      'notesLabel': 'नोट्स',
      'enterTaskNamePrompt': 'कृपया टास्क नाम दर्ज करें',
      'noDueDate': 'कोई देय तिथि नहीं',
      'statusLabel': 'स्थिति',
      'priorityLabelText': 'प्राथमिकता',
      'assignToFamilyMembers': 'परिवार के सदस्यों को सौंपें',
      'taskStatusTodo': 'करना है',
      'taskStatusInProgress': 'प्रगति में',
      'taskStatusBlocked': 'रुका हुआ',
      'taskStatusCompleted': 'पूर्ण',
      'priorityHigh': 'उच्च',
      'priorityMedium': 'मध्यम',
      'priorityLow': 'निम्न',
      'openOfTotal': '{open} खुले में से {total}',
    },
  };

  String get familyCalendar => _read('familyCalendar');
  String get calendar => _read('calendar');
  String get agenda => _read('agenda');
  String get todo => _read('todo');
  String get settings => _read('settings');
  String get familyMembers => _read('familyMembers');
  String get categories => _read('categories');
  String get appSettings => _read('appSettings');
  String get theme => _read('theme');
  String get language => _read('language');
  String get account => _read('account');
  String get about => _read('about');
  String get signOut => _read('signOut');
  String get english => _read('english');
  String get spanish => _read('spanish');
  String get hindi => _read('hindi');
  String get shopping => _read('shopping');
  String get tasks => _read('tasks');
  String get quickAdd => _read('quickAdd');
  String get recentItems => _read('recentItems');
  String get addItem => _read('addItem');
  String get changeName => _read('changeName');
  String get addPhoto => _read('addPhoto');
  String get chooseTheme => _read('chooseTheme');
  String get themeSaved => _read('themeSaved');
  String get chooseLanguage => _read('chooseLanguage');
  String get notLoggedIn => _read('notLoggedIn');
  String get editDisplayName => _read('editDisplayName');
  String get displayName => _read('displayName');
  String get cancel => _read('cancel');
  String get save => _read('save');
  String get create => _read('create');
  String get close => _read('close');
  String get profilePhotoUpdated => _read('profilePhotoUpdated');
  String get displayNameUpdated => _read('displayNameUpdated');
  String get pleaseEnterDisplayName => _read('pleaseEnterDisplayName');
  String get unableToSelectImage => _read('unableToSelectImage');
  String get selectProfileImage => _read('selectProfileImage');
  String get chooseFromApp => _read('chooseFromApp');
  String get useThisPhoto => _read('useThisPhoto');
  String get familyTaskLists => _read('familyTaskLists');
  String get myTaskLists => _read('myTaskLists');
  String get taskWorkspaceSubtitle => _read('taskWorkspaceSubtitle');
  String get shoppingWorkspaceSubtitle => _read('shoppingWorkspaceSubtitle');
  String get workspace => _read('workspace');
  String get scope => _read('scope');
  String get view => _read('view');
  String get myLists => _read('myLists');
  String get compact => _read('compact');
  String get detailed => _read('detailed');
  String get newList => _read('newList');
  String get searchLists => _read('searchLists');
  String get defaultShoppingLists => _read('defaultShoppingLists');
  String get joinFamilyShopping => _read('joinFamilyShopping');
  String get shoppingNeedsFamily => _read('shoppingNeedsFamily');
  String get openList => _read('openList');
  String get listDetails => _read('listDetails');
  String get addAnotherItem => _read('addAnotherItem');
  String get noItemsYet => _read('noItemsYet');
  String get addFirstItem => _read('addFirstItem');
  String get groceryList => _read('groceryList');
  String get packingList => _read('packingList');
  String get giftIdeas => _read('giftIdeas');
  String get houseProjects => _read('houseProjects');
  String get moviesToWatch => _read('moviesToWatch');
  String get tripIdeas => _read('tripIdeas');
  String get others => _read('others');
  String get itemName => _read('itemName');
  String get quantity => _read('quantity');
  String get category => _read('category');
  String get aisle => _read('aisle');
  String get note => _read('note');
  String get searchGroceryItems => _read('searchGroceryItems');
  String get typeCustomItem => _read('typeCustomItem');
  String get aboutTitle => _read('aboutTitle');
  String get aboutBody => _read('aboutBody');
  String get signOutTitle => _read('signOutTitle');
  String get signOutPrompt => _read('signOutPrompt');
  String get showBundledAvatars => _read('showBundledAvatars');
  String get usePhotoFromApp => _read('usePhotoFromApp');
  String get enterItem => _read('enterItem');
  String get chooseListName => _read('chooseListName');
  String get customAisles => _read('customAisles');
  String get editItem => _read('editItem');
  String get addItemTitle => _read('addItemTitle');
  String get delete => _read('delete');
  String get edit => _read('edit');
  String get add => _read('add');
  String get shoppingListStyleHint => _read('shoppingListStyleHint');
  String get languageUpdated => _read('languageUpdated');
  String get shareWithFamily => _read('shareWithFamily');
  String get privateList => _read('privateList');
  String get sharedList => _read('sharedList');
  String get deleteList => _read('deleteList');
  String get makePrivate => _read('makePrivate');
  String get reorderHint => _read('reorderHint');
  String get events => _read('events');
  String get calendarView => _read('calendarView');
  String get openCalendar => _read('openCalendar');
  String get loggedIn => _read('loggedIn');
  String get configuration => _read('configuration');
  String get agendaDescription => _read('agendaDescription');
  String get noUpcomingEvents => _read('noUpcomingEvents');
  String get createListTitle => _read('createListTitle');
  String get editListTitle => _read('editListTitle');
  String get listName => _read('listName');
  String get descriptionLabel => _read('descriptionLabel');
  String get enterListNamePrompt => _read('enterListNamePrompt');
  String get addTaskTitle => _read('addTaskTitle');
  String get editTaskTitle => _read('editTaskTitle');
  String get taskName => _read('taskName');
  String get notesLabel => _read('notesLabel');
  String get enterTaskNamePrompt => _read('enterTaskNamePrompt');
  String get noDueDate => _read('noDueDate');
  String get statusLabel => _read('statusLabel');
  String get priorityLabelText => _read('priorityLabelText');
  String get assignToFamilyMembers => _read('assignToFamilyMembers');
  String get taskStatusTodo => _read('taskStatusTodo');
  String get taskStatusInProgress => _read('taskStatusInProgress');
  String get taskStatusBlocked => _read('taskStatusBlocked');
  String get taskStatusCompleted => _read('taskStatusCompleted');
  String get priorityHigh => _read('priorityHigh');
  String get priorityMedium => _read('priorityMedium');
  String get priorityLow => _read('priorityLow');
  String get createEvent => _read('createEvent');
  String get addEvent => _read('addEvent');
  String get editEvent => _read('editEvent');
  String get eventTitle => _read('eventTitle');
  String get allDay => _read('allDay');
  String get startTime => _read('startTime');
  String get endTime => _read('endTime');
  String get repeat => _read('repeat');
  String get repeatOn => _read('repeatOn');
  String get doesNotRepeat => _read('doesNotRepeat');
  String get daily => _read('daily');
  String get weekly => _read('weekly');
  String get monthly => _read('monthly');
  String get yearly => _read('yearly');
  String get noRecurrenceEndDate => _read('noRecurrenceEndDate');
  String get clearRecurrenceEndDate => _read('clearRecurrenceEndDate');
  String get eventIcon => _read('eventIcon');
  String get chooseEventIcon => _read('chooseEventIcon');
  String get chooseEventIconHint => _read('chooseEventIconHint');
  String get none => _read('none');
  String get location => _read('location');
  String get saveEvent => _read('saveEvent');
  String get saveChanges => _read('saveChanges');
  String get selectCategory => _read('selectCategory');
  String get noCategoriesAvailable => _read('noCategoriesAvailable');
  String get pleaseEnterEventTitle => _read('pleaseEnterEventTitle');
  String get pleaseSelectCategory => _read('pleaseSelectCategory');
  String get endDateBeforeStartDate => _read('endDateBeforeStartDate');
  String get endTimeBeforeStartTime => _read('endTimeBeforeStartTime');
  String get recurrenceEndBeforeEventDate => _read('recurrenceEndBeforeEventDate');
  String get selectWeeklyRecurrenceDay => _read('selectWeeklyRecurrenceDay');
  String get eventUpdatedSuccessfully => _read('eventUpdatedSuccessfully');
  String get eventAddedSuccessfully => _read('eventAddedSuccessfully');

  String shoppingItemsCount(int count) {
    final template = count == 1
        ? _read('shoppingItemsCountOne')
        : _read('shoppingItemsCountMany');
    return template.replaceAll('{count}', '$count');
  }

  String activeItemsCount(int count) {
    final template = count == 1
        ? _read('activeItemsCountOne')
        : _read('activeItemsCountMany');
    return template.replaceAll('{count}', '$count');
  }

  String loggedInAs(String name) {
    return '${_read('loggedIn')}: $name';
  }

  String openOfTotal(int open, int total) {
    return _read('openOfTotal')
        .replaceAll('{open}', '$open')
        .replaceAll('{total}', '$total');
  }

  String repeatUntil(String date) {
    return _read('repeatUntil').replaceAll('{date}', date);
  }

  String spansDays(int count) {
    return _read('spansDays').replaceAll('{count}', '$count');
  }

  String _read(String key) {
    return _values[languageCode]?[key] ?? _values['en']![key] ?? key;
  }
}
