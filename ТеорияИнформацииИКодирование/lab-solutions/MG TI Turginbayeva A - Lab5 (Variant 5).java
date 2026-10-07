import java.util.*;
import java.util.stream.*;

class Lab5Huffman {

    record Node(String name, int w, Node up, Node down) { }

    record Table(Node root, List<String> lines, String weights) { }

    static String p(int w) {
        return String.format("%.2f", w / 100.0);
    }

    static String show(List<Node> col) {
        return col.stream().map(n -> n.name() + " " + p(n.w())).collect(Collectors.joining(" | "));
    }

    static String weights(List<Node> col) {
        return col.stream().map(n -> String.valueOf(n.w())).collect(Collectors.joining(" "));
    }

    static Table huffman(List<Node> msgs, boolean mergedHigh) {
        List<Node> col = new ArrayList<>(msgs);
        col.sort((a, b) -> b.w() - a.w());
        List<String> lines = new ArrayList<>(List.of("исходный столбец: " + show(col)));
        StringBuilder ws = new StringBuilder(weights(col));
        for (int step = 1; col.size() > 1; step++) {
            Node down = col.remove(col.size() - 1);
            Node up = col.remove(col.size() - 1);
            Node sum = new Node("S" + step, up.w() + down.w(), up, down);
            int pos = 0;
            while (pos < col.size() && (col.get(pos).w() > sum.w() || (!mergedHigh && col.get(pos).w() == sum.w()))) pos++;
            col.add(pos, sum);
            lines.add("шаг " + step + ": " + sum.name() + " = " + up.name() + " + " + down.name() + " = " + p(sum.w()) + "; столбец: " + show(col));
            ws.append(" / ").append(weights(col));
        }
        return new Table(col.get(0), lines, ws.toString());
    }

    static void codes(Node n, String prefix, Map<String, String> out) {
        if (n.up() == null) {
            out.put(n.name(), prefix);
        } else {
            codes(n.up(), prefix + "0", out);
            codes(n.down(), prefix + "1", out);
        }
    }

    static boolean prefixFree(Collection<String> codes) {
        List<String> c = new ArrayList<>(codes);
        for (int i = 0; i < c.size(); i++)
            for (int j = 0; j < c.size(); j++)
                if (i != j && c.get(j).startsWith(c.get(i))) return false;
        return true;
    }

    static boolean roundTrip(List<String> names, Map<String, String> code) {
        StringBuilder bits = new StringBuilder();
        names.forEach(s -> bits.append(code.get(s)));
        Map<String, String> back = new HashMap<>();
        code.forEach((s, c) -> back.put(c, s));
        List<String> out = new ArrayList<>();
        String cur = "";
        for (char ch : bits.toString().toCharArray()) {
            cur += ch;
            if (back.containsKey(cur)) {
                out.add(back.get(cur));
                cur = "";
            }
        }
        return out.equals(names) && cur.isEmpty();
    }

    static int minSum(int[] w, int i, int used, int maxLen) {
        if (i == w.length) return 0;
        int best = Integer.MAX_VALUE;
        for (int len = 1; len <= maxLen; len++) {
            int u = used + (1 << (maxLen - len));
            if (u > 1 << maxLen) continue;
            int rest = minSum(w, i + 1, u, maxLen);
            if (rest != Integer.MAX_VALUE) best = Math.min(best, w[i] * len + rest);
        }
        return best;
    }

    static int total(List<Node> sorted, Map<String, String> code) {
        return sorted.stream().mapToInt(m -> m.w() * code.get(m.name()).length()).sum();
    }

    static String solve(String title, String[] names, int[] w, double t) {
        System.out.println("=== " + title + " ===");
        List<Node> msgs = new ArrayList<>();
        for (int i = 0; i < w.length; i++) msgs.add(new Node(names[i], w[i], null, null));
        List<Node> sorted = new ArrayList<>(msgs);
        sorted.sort((a, b) -> b.w() - a.w());

        Table table = huffman(msgs, true);
        table.lines().forEach(System.out::println);
        Map<String, String> code = new HashMap<>();
        codes(table.root(), "", code);
        for (Node m : sorted)
            System.out.printf("%-3s p = %s  код %-6s длина %d%n", m.name(), p(m.w()), code.get(m.name()), code.get(m.name()).length());

        double L = total(sorted, code) / 100.0, H = 0;
        for (Node m : sorted) H -= m.w() / 100.0 * Math.log(m.w() / 100.0) / Math.log(2);
        int uniform = 32 - Integer.numberOfLeadingZeros(w.length - 1);
        System.out.printf("L = %.4f; H = %.4f; L - H = %.4f; H/L = %.2f%%%n", L, H, L - H, H / L * 100);
        System.out.printf("равномерный код: %d двоичных символа на сообщение, эффективность H/%d = %.2f%%%n", uniform, uniform, H / uniform * 100);

        int maxLen = code.values().stream().mapToInt(String::length).max().getAsInt();
        int kraft = code.values().stream().mapToInt(c -> 1 << (maxLen - c.length())).sum();
        List<String> text = new ArrayList<>();
        for (int k = 0; k < 3; k++) sorted.forEach(m -> text.add(m.name()));
        System.out.printf("неравенство Крафта: сумма 2^-l = %.1f; префиксность: %b; кодирование и декодирование: %b%n",
                (double) kraft / (1 << maxLen), prefixFree(code.values()), roundTrip(text, code));
        int best = minSum(sorted.stream().mapToInt(Node::w).toArray(), 0, 0, w.length - 1);
        System.out.printf("перебор всех наборов длин по неравенству Крафта: минимальная L = %.4f; код Хаффмана оптимален: %b%n",
                best / 100.0, best == total(sorted, code));
        if (t > 0)
            System.out.printf("пропускная способность: C = L/t = %.2f бит/с; нижняя граница H/t = %.2f бит/с; равномерный код %.2f бит/с%n",
                    L / t, H / t, uniform / t);

        Map<String, String> other = new HashMap<>();
        codes(huffman(msgs, false).root(), "", other);
        System.out.println("сумма ниже равных: длины " + sorted.stream().map(m -> String.valueOf(other.get(m.name()).length())).collect(Collectors.joining(" "))
                + ", L = " + String.format("%.4f", total(sorted, other) / 100.0));
        System.out.println();
        return table.weights();
    }

    public static void main(String[] args) {
        Locale.setDefault(Locale.ROOT);
        solve("Задание 1: алфавит L G N P D B T X, t = 0.1 с", new String[]{"L", "G", "N", "P", "D", "B", "T", "X"}, new int[]{20, 30, 1, 9, 30, 3, 4, 3}, 0.1);
        solve("Задание 2: A1..A4 = 0.13, A5..A7 = 0.16", new String[]{"A1", "A2", "A3", "A4", "A5", "A6", "A7"}, new int[]{13, 13, 13, 13, 16, 16, 16}, 0);
        String columns = solve("Пример методички (таблица 2)", new String[]{"1", "2", "3", "4", "5", "6"}, new int[]{40, 20, 20, 10, 5, 5}, 0);
        System.out.println("столбцы таблицы 2 методички воспроизведены: " + columns.equals("40 20 20 10 5 5 / 40 20 20 10 10 / 40 20 20 20 / 40 40 20 / 60 40 / 100"));
    }
}
