# Navigation

## React Navigation — stack/tab/drawer

Type the param list centrally in 1 place (`navigation/types.ts`); every screen uses `NativeStackScreenProps`/hooks with generics from that param list — do not use `navigation.navigate('Screen', {...})` with arbitrary params that are not type-checked.

```tsx
// navigation/types.ts
export type RootStackParamList = {
  Home: undefined;
  UserDetail: { userId: string };
};

// screens/UserDetailScreen.tsx
type Props = NativeStackScreenProps<RootStackParamList, 'UserDetail'>;
function UserDetailScreen({ route }: Props) {
  const { userId } = route.params; // type-safe, no as/any needed
}
```

Keep route definitions centralized in 1 navigator; do not scatter `<Stack.Screen>` definitions across the app. Put the deep link config (`linking`) next to the root navigator to make route ↔ URL scheme easy to compare.

## Expo Router — file-based

File/directory names in `app/` are the routes — `(group)` groups routes without appearing in the URL (for example separating `(auth)` and `(tabs)` with different layouts), `[param].tsx` for dynamic routes.

```
app/
├── users/
│   ├── index.tsx        # /users
│   └── [id].tsx          # /users/:id
```

```tsx
// app/users/[id].tsx
import { useLocalSearchParams } from 'expo-router';
export default function UserDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
}
```

## Which to choose

If the project already has one of the two, follow it — do not migrate midway unless explicitly requested (changing the routing mechanism is a major architecture change, affecting deep links, analytics screen tracking, animation transitions).

New project: Expo Router fits when already using managed Expo and wanting Next.js-like route conventions (less boilerplate defining navigators by hand); React Navigation fits when you need fine control over navigators (complex nested navigators, custom transitions, not using Expo).

## Anti-pattern

- Passing a callback function via `navigation.navigate('Screen', { onDone: () => {} })` — params must be serializable (deep links and state persistence will break); use state management/an event emitter instead of stuffing a function into route params.
- Calling `navigation.reset` carelessly to "make sure" of landing on the right screen — use it only when you truly need to clear the stack history (after login/logout); overuse breaks the natural back button UX.
